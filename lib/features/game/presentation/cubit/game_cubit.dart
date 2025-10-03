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
          order: Terrain.values,
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
        effects: const BoardEffects(), // reset effetti
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

      t.cancel();
      switch (state.phase) {
        case Phase.drafting:
          _lockChoicesAndReveal();
          _startTimer(); // conterà la reveal
          break;
        case Phase.reveal:
          _scoreRound(
            state.currentTerrain,
            state.oppPreview?.sprint,
            state.oppPreview?.block,
          );
          break;
        case Phase.recap:
          _nextRound();
          break;
        default:
          break;
      }
    });
  }

  // ---------- DRAFTING ----------
  void selectCard(GameCard card) {
    if (state.phase != Phase.drafting) return;

    final isSprint = card.kind == CardKind.sprint;
    final isBlock = card.kind == CardKind.block;

    final choice = state.myPrivate.choice;
    final alreadySprint = choice.sprint != null;
    final alreadyBlock = choice.block != null;

    final inHand = state.myPrivate.hand.any((c) => c.id == card.id);
    if (!inHand) return;

    final manaCost = card.manaCost;
    if (state.me.mana < manaCost) return;
    if (isSprint && alreadySprint) return;
    if (isBlock && alreadyBlock) return;

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

  // ---------- REVEAL ----------
  void _lockChoicesAndReveal() {
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
        effects: const BoardEffects(), // reset effetti ad inizio reveal
      ),
    );
  }

  // Gioca una carta trick dalla mano (solo in reveal)
  void playTrick(GameCard card) {
    if (state.phase != Phase.reveal) return;
    if (card.kind != CardKind.trick) return;
    if (card.trick == null || card.trick!.isNoop) return;

    final inHand = state.myPrivate.hand.any((c) => c.id == card.id);
    if (!inHand) return;

    final manaCost = card.manaCost;
    if (state.me.mana < manaCost) return;

    // Applica effetti
    final newEffects = BoardEffects.applyTrick(state.effects, card.trick!);

    // Rimuovi dalla mano e scala mana
    final newHand = [...state.myPrivate.hand]
      ..removeWhere((c) => c.id == card.id);

    emit(
      state.copyWith(
        myPrivate: state.myPrivate.copyWith(hand: newHand),
        me: state.me.copyWith(mana: state.me.mana - manaCost),
        effects: newEffects,
        revealedCardIds: [...state.revealedCardIds, card.id],
      ),
    );
  }

  // ---------- SCORING ----------
  void _scoreRound(Terrain t, GameCard? oppSprint, GameCard? oppBlock) {
    final mySprint = state.myPrivate.choice.sprint;
    final myBlock = state.myPrivate.choice.block;

    // Applica distruzioni: se distrutto, valore = 0
    final eff = state.effects;

    final bool mySprintDestroyed = eff.destroyMySprint;
    final bool myBlockDestroyed = eff.destroyMyBlock;
    final bool oppSprintDestroyed = eff.destroyOppSprint;
    final bool oppBlockDestroyed = eff.destroyOppBlock;

    int mySprintVal = (mySprintDestroyed || mySprint == null)
        ? 0
        : mySprint.valueOn(t) + eff.mySprintDelta;
    int myBlockVal = (myBlockDestroyed || myBlock == null)
        ? 0
        : myBlock.valueOn(t) + eff.myBlockDelta;
    int oppSprintVal = (oppSprintDestroyed || oppSprint == null)
        ? 0
        : oppSprint.valueOn(t) + eff.oppSprintDelta;
    int oppBlockVal = (oppBlockDestroyed || oppBlock == null)
        ? 0
        : oppBlock.valueOn(t) + eff.oppBlockDelta;

    // clamp a zero minimo
    mySprintVal = max(mySprintVal, 0);
    myBlockVal = max(myBlockVal, 0);
    oppSprintVal = max(oppSprintVal, 0);
    oppBlockVal = max(oppBlockVal, 0);

    final myDelta = max(mySprintVal - oppBlockVal, 0);
    final oppDelta = max(oppSprintVal - myBlockVal, 0);

    final res = RoundResult(
      terrain: t,
      me: state.myPrivate.choice,
      opp: SecretChoice(sprint: oppSprint, block: oppBlock),
      delta: myDelta,
    );

    emit(
      state.copyWith(
        phase: Phase.scoring,
        results: [...state.results, res],
        me: state.me.copyWith(score: state.me.score + myDelta),
        opp: state.opp.copyWith(score: state.opp.score + oppDelta),
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
        effects: const BoardEffects(), // reset effetti per nuovo round
      ),
    );

    _startTimer();
  }

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
