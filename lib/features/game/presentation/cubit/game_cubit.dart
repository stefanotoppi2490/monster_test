import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monster/core/config.dart';
import 'package:monster/core/models/models.dart';
import 'package:monster/features/game/domain/repositories/game_repo.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final GameRepo repo;
  Timer? _ticker;
  Deck _myDeck = Deck(const []);
  Deck _oppDeck = Deck(const []);
  final _rng = Random();

  GameCubit({required this.repo})
    : super(
        GameState.initial(
          order: Terrain.values, // placeholder, sovrascritto in startMatch
          results: const [],
          revealed: const [],
          me: const PlayerPublic(score: 0, mana: 0),
          opp: const PlayerPublic(score: 0, mana: 0),
          myPriv: const PlayerPrivate(hand: [], choice: SecretChoice()),
          oppPreview: const SecretChoice(),
        ),
      );

  void startMatch() {
    final order = repo.randomTerrainOrder(kRounds);
    _myDeck = repo.starterDeck();
    _oppDeck = repo.starterDeck();

    // pesca iniziale: fino a 5
    final (d2, startHand) = repo.draw(_myDeck, kHandSize);
    _myDeck = d2;

    final me = state.me.copyWith(mana: kBaseManaPerTurn);
    final opp = state.opp.copyWith(mana: kBaseManaPerTurn);

    emit(
      state.copyWith(
        terrainOrder: order,
        roundIndex: 0,
        phase: Phase.drafting,
        secondsLeft: kRoundSeconds,
        me: me,
        opp: opp,
        myPrivate: state.myPrivate.copyWith(
          hand: startHand,
          choice: const SecretChoice(),
        ),
        results: [],
        revealedCardIds: [],
        oppPreview: const SecretChoice(),
      ),
    );

    _startTimer();
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.secondsLeft - 1;
      if (left > 0) {
        emit(state.copyWith(secondsLeft: left));
        return;
      }

      // left == 0
      t.cancel();
      switch (state.phase) {
        case Phase.drafting:
          _lockChoicesAndReveal();
          break;
        case Phase.recap:
          _nextRound();
          break;
        default:
          // niente timer nelle altre fasi
          break;
      }
    });
  }

  void selectCard(GameCard card) {
    if (state.phase != Phase.drafting) return;
    // rispettare limiti: max 1 sprint + max 1 block, e mana
    final isSprint = card.kind == CardKind.sprint;
    final isBlock = card.kind == CardKind.block;

    final choice = state.myPrivate.choice;
    final alreadySprint = choice.sprint != null;
    final alreadyBlock = choice.block != null;

    final manaCost = card.manaCost;
    if (state.me.mana < manaCost) return; // non basta mana

    if (isSprint && alreadySprint) return;
    if (isBlock && alreadyBlock) return;

    // applica scelta + scalare mana + togliere dalla mano
    final newHand = [...state.myPrivate.hand]
      ..removeWhere((c) => c.id == card.id);
    final newChoice = SecretChoice(
      sprint: isSprint ? card : choice.sprint,
      block: isBlock ? card : choice.block,
    );

    emit(
      state.copyWith(
        myPrivate: state.myPrivate.copyWith(hand: newHand, choice: newChoice),
        me: state.me.copyWith(mana: state.me.mana - manaCost),
      ),
    );
  }

  void undoChoice(CardKind kind) {
    if (state.phase != Phase.drafting) return;
    final choice = state.myPrivate.choice;
    final card = (kind == CardKind.sprint) ? choice.sprint : choice.block;
    if (card == null) return;

    final newHand = [...state.myPrivate.hand, card];
    final newChoice = SecretChoice(
      sprint: kind == CardKind.sprint ? null : choice.sprint,
      block: kind == CardKind.block ? null : choice.block,
    );
    emit(
      state.copyWith(
        myPrivate: state.myPrivate.copyWith(hand: newHand, choice: newChoice),
        me: state.me.copyWith(mana: state.me.mana + card.manaCost),
      ),
    );
  }

  void _lockChoicesAndReveal() {
    final terrain = state.currentTerrain;

    // Bot: pesca 5 per turno per semplificare (indipendente dalla tua mano)
    final (deckAfter, oppHand) = repo.draw(_oppDeck, kHandSize);
    _oppDeck = deckAfter;

    final oppOptionsSprint = oppHand
        .where((c) => c.kind == CardKind.sprint)
        .toList();
    final oppOptionsBlock = oppHand
        .where((c) => c.kind == CardKind.block)
        .toList();

    GameCard? oppSprint;
    GameCard? oppBlock;

    if (_rng.nextBool() && oppOptionsSprint.isNotEmpty) {
      oppSprint = oppOptionsSprint[_rng.nextInt(oppOptionsSprint.length)];
    }
    if (_rng.nextBool() && oppOptionsBlock.isNotEmpty) {
      oppBlock = oppOptionsBlock[_rng.nextInt(oppOptionsBlock.length)];
    }

    emit(
      state.copyWith(
        phase: Phase.reveal,
        secondsLeft: kRevealSeconds,
        oppPreview: SecretChoice(sprint: oppSprint, block: oppBlock),
        revealedCardIds: [
          if (state.myPrivate.choice.sprint != null)
            state.myPrivate.choice.sprint!.id,
          if (state.myPrivate.choice.block != null)
            state.myPrivate.choice.block!.id,
          if (oppSprint != null) oppSprint.id,
          if (oppBlock != null) oppBlock.id,
        ],
      ),
    );

    Future.delayed(Duration(seconds: kRevealSeconds), () {
      _scoreRound(terrain, oppSprint, oppBlock);
    });
  }

  void _scoreRound(Terrain t, GameCard? oppSprint, GameCard? oppBlock) {
    final mySprint = state.myPrivate.choice.sprint;
    final myBlock = state.myPrivate.choice.block;

    final mySprintVal = mySprint?.valueOn(t) ?? 0;
    final myBlockVal = myBlock?.valueOn(t) ?? 0;
    final oppSprintVal = oppSprint?.valueOn(t) ?? 0;
    final oppBlockVal = oppBlock?.valueOn(t) ?? 0;

    final myDelta = max(mySprintVal - oppBlockVal, 0);
    final oppDelta = max(oppSprintVal - myBlockVal, 0);

    final res = RoundResult(
      terrain: t,
      me: state.myPrivate.choice,
      opp: SecretChoice(sprint: oppSprint, block: oppBlock),
      // se RoundResult ha un unico delta, teniamo il "mio".
      delta: myDelta,
    );

    emit(
      state.copyWith(
        phase: Phase.scoring,
        results: [...state.results, res],
        me: state.me.copyWith(score: state.me.score + myDelta),
        opp: state.opp.copyWith(score: state.opp.score + oppDelta),
        // pulisco l’anteprima avversaria se la uso (vedi punto 2)
        oppPreview: null,
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (kEnableBetweenRoundsPause) {
        emit(
          state.copyWith(
            phase: Phase.recap,
            secondsLeft: kBetweenRoundsPauseSeconds,
          ),
        );
        _startTimer();
      } else {
        _nextRound();
      }
    });
  }

  void _nextRound() {
    if (state.lastRound) {
      emit(state.copyWith(phase: Phase.finished));
      return;
    }

    // rimuovi dalla mano le carte effettivamente giocate (sono già state tolte in selectCard)
    // quindi qui basta refill
    final (newDeck, drawn) = _refillHandTo(
      kHandSize,
      _myDeck,
      state.myPrivate.hand,
    );
    _myDeck = newDeck;

    final newMana = (state.me.mana + kBaseManaPerTurn).clamp(0, kMaxManaCap);
    final nextIndex = state.roundIndex + 1;

    emit(
      state.copyWith(
        roundIndex: nextIndex,
        phase: Phase.drafting,
        secondsLeft: kRoundSeconds,
        myPrivate: state.myPrivate.copyWith(
          hand: drawn,
          choice: const SecretChoice(),
        ),
        revealedCardIds: [],
        me: state.me.copyWith(mana: newMana),
        opp: state.opp.copyWith(
          mana: (state.opp.mana + kBaseManaPerTurn).clamp(0, kMaxManaCap),
        ),
        oppPreview: const SecretChoice(),
      ),
    );

    _startTimer();
  }

  /// Refill: pesca dal deck solo le carte necessarie per arrivare a `size`
  (Deck, List<GameCard>) _refillHandTo(
    int size,
    Deck deck,
    List<GameCard> current,
  ) {
    if (current.length >= size) return (deck, current);
    final need = size - current.length;
    final (d2, top) = repo.draw(deck, need);
    return (d2, [...current, ...top]);
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
