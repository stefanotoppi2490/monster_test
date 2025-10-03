import 'package:monster/core/config.dart';
import 'package:monster/core/models/models.dart';

enum Phase { drafting, reveal, recap, scoring, transition, finished }

class PlayerPublic {
  final int score;
  final int mana; // visibile il totale
  const PlayerPublic({required this.score, required this.mana});

  PlayerPublic copyWith({int? score, int? mana}) =>
      PlayerPublic(score: score ?? this.score, mana: mana ?? this.mana);
}

class PlayerPrivate {
  final List<GameCard> hand;
  final SecretChoice choice;
  const PlayerPrivate({required this.hand, required this.choice});

  PlayerPrivate copyWith({List<GameCard>? hand, SecretChoice? choice}) =>
      PlayerPrivate(hand: hand ?? this.hand, choice: choice ?? this.choice);
}

class GameState {
  /// Indice round corrente: 0..(terrainOrder.length - 1)
  final int roundIndex;

  /// Ordine dei terreni per la partita (lunghezza = kRounds, vincolo max 4 per terreno)
  final List<Terrain> terrainOrder;

  final Phase phase;
  final int secondsLeft;

  final PlayerPublic me;
  final PlayerPublic opp;

  final PlayerPrivate myPrivate;

  /// Storico risultati round passati
  final List<RoundResult> results;

  /// Id carte rivelate per triggerare flip animazioni
  final List<String> revealedCardIds;

  /// Scelte dell’avversario nel round corrente (per fase reveal/recap).
  /// Può essere null (ad es. dopo lo scoring la resetti).
  final SecretChoice? oppPreview;

  const GameState({
    required this.roundIndex,
    required this.terrainOrder,
    required this.phase,
    required this.secondsLeft,
    required this.me,
    required this.opp,
    required this.myPrivate,
    required this.results,
    required this.revealedCardIds,
    required this.oppPreview,
  });

  /// Terreno del round corrente (safe se l’ordine è non-vuoto)
  Terrain get currentTerrain => terrainOrder[roundIndex];

  /// True se siamo all’ultimo round della partita
  bool get lastRound => roundIndex >= terrainOrder.length - 1;

  // Sentinel per consentire di "passare null" a oppPreview dentro copyWith
  static const Object _sentinel = Object();

  GameState copyWith({
    int? roundIndex,
    List<Terrain>? terrainOrder,
    Phase? phase,
    int? secondsLeft,
    PlayerPublic? me,
    PlayerPublic? opp,
    PlayerPrivate? myPrivate,
    List<RoundResult>? results,
    List<String>? revealedCardIds,

    /// Usa questo parametro per poter settare esplicitamente null.
    /// Esempio:
    ///   state.copyWith(oppPreview: null)  // azzera
    ///   state.copyWith()                  // lascia invariato
    Object? oppPreview = _sentinel,
  }) {
    return GameState(
      roundIndex: roundIndex ?? this.roundIndex,
      terrainOrder: terrainOrder ?? this.terrainOrder,
      phase: phase ?? this.phase,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      me: me ?? this.me,
      opp: opp ?? this.opp,
      myPrivate: myPrivate ?? this.myPrivate,
      results: results ?? this.results,
      revealedCardIds: revealedCardIds ?? this.revealedCardIds,
      oppPreview: identical(oppPreview, _sentinel)
          ? this.oppPreview
          : oppPreview as SecretChoice?,
    );
  }

  factory GameState.initial({
    required List<Terrain> order,
    required List<RoundResult> results,
    required List<String> revealed,
    required PlayerPublic me,
    required PlayerPublic opp,
    required PlayerPrivate myPriv,
    required SecretChoice oppPreview,
  }) {
    return GameState(
      roundIndex: 0,
      terrainOrder: order,
      phase: Phase.drafting,
      secondsLeft: kRoundSeconds, // <-- usa config
      me: me,
      opp: opp,
      myPrivate: myPriv,
      results: results,
      revealedCardIds: revealed,
      oppPreview: oppPreview,
    );
  }
}
