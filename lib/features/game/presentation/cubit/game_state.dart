import 'package:monster/core/config.dart';
import 'package:monster/core/models/models.dart';

enum Phase { drafting, reveal, recap, scoring, transition, finished }

class PlayerPublic {
  final int score;
  final int mana;
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
  final int roundIndex;
  final List<Terrain> terrainOrder;
  final Phase phase;
  final int secondsLeft;

  final PlayerPublic me;
  final PlayerPublic opp;

  final PlayerPrivate myPrivate;

  final List<RoundResult> results;
  final List<String> revealedCardIds;

  final SecretChoice? oppPreview;

  // ⬇️ Effetti trick del round corrente
  final BoardEffects effects;

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
    required this.effects,
  });

  Terrain get currentTerrain => terrainOrder[roundIndex];
  bool get lastRound => roundIndex >= terrainOrder.length - 1;

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
    Object? oppPreview = _sentinel,
    BoardEffects? effects,
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
      effects: effects ?? this.effects,
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
      secondsLeft: kRoundSeconds,
      me: me,
      opp: opp,
      myPrivate: myPriv,
      results: results,
      revealedCardIds: revealed,
      oppPreview: null,
      effects: const BoardEffects(), // ⬅️ reset
    );
  }
}
