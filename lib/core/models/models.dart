import 'dart:math';

enum Terrain { asfalto, acqua, sabbia, fango }

extension TerrainX on Terrain {
  String get label => switch (this) {
    Terrain.asfalto => 'ASFALTO',
    Terrain.acqua => 'ACQUA',
    Terrain.sabbia => 'SABBIA',
    Terrain.fango => 'FANGO',
  };
}

// Tipo carta
enum CardKind { sprint, block, trick } // ⬅️ rinominato “instant” → “trick”

enum TargetSide { me, opp }

// Specifica di una Trick; i campi null/0 sono ignorati
class TrickSpec {
  final TargetSide side; // su chi applico l’effetto
  final int addToSprinter;
  final int addToBlocker;
  final int removeFromSprinter;
  final int removeFromBlocker;
  final bool destroySprinter;
  final bool destroyBlocker;

  const TrickSpec({
    required this.side,
    this.addToSprinter = 0,
    this.addToBlocker = 0,
    this.removeFromSprinter = 0,
    this.removeFromBlocker = 0,
    this.destroySprinter = false,
    this.destroyBlocker = false,
  });

  bool get isNoop =>
      addToSprinter == 0 &&
      addToBlocker == 0 &&
      removeFromSprinter == 0 &&
      removeFromBlocker == 0 &&
      !destroySprinter &&
      !destroyBlocker;
}

// Carta base
class GameCard {
  final String id;
  final String name;
  final CardKind kind;
  final Map<Terrain, int> valueByTerrain; // per le trick metti tutto 0
  final int manaCost;
  final TrickSpec? trick; // ⬅️ solo se kind == trick
  final String imagePath; // ⬅️ percorso dell'immagine della carta

  const GameCard({
    required this.id,
    required this.name,
    required this.kind,
    required this.valueByTerrain,
    required this.manaCost,
    this.trick,
    required this.imagePath,
  });

  int valueOn(Terrain t) => valueByTerrain[t] ?? 0;

  GameCard copyWith({String? id}) => GameCard(
    id: id ?? this.id,
    name: name,
    kind: kind,
    valueByTerrain: valueByTerrain,
    manaCost: manaCost,
    trick: trick,
    imagePath: imagePath,
  );
}

// Un “mazzo” semplice da 30 carte mix sprint/block
class Deck {
  final List<GameCard> cards;
  Deck(this.cards);

  Deck shuffled([Random? r]) {
    final copy = [...cards];
    copy.shuffle(r ?? Random());
    return Deck(copy);
  }

  (Deck, List<GameCard>) draw(int n) {
    final take = cards.take(n).toList();
    final rest = cards.skip(n).toList();
    return (Deck(rest), take);
  }
}

// Scelte segrete (giocate) nel round
class SecretChoice {
  final GameCard? sprint;
  final GameCard? block;

  const SecretChoice({this.sprint, this.block});

  bool get isEmpty => sprint == null && block == null;
}

// Effetti applicati sul board nel round corrente
class BoardEffects {
  final int mySprintDelta;
  final int myBlockDelta;
  final int oppSprintDelta;
  final int oppBlockDelta;

  final bool destroyMySprint;
  final bool destroyMyBlock;
  final bool destroyOppSprint;
  final bool destroyOppBlock;

  const BoardEffects({
    this.mySprintDelta = 0,
    this.myBlockDelta = 0,
    this.oppSprintDelta = 0,
    this.oppBlockDelta = 0,
    this.destroyMySprint = false,
    this.destroyMyBlock = false,
    this.destroyOppSprint = false,
    this.destroyOppBlock = false,
  });

  BoardEffects copyWith({
    int? mySprintDelta,
    int? myBlockDelta,
    int? oppSprintDelta,
    int? oppBlockDelta,
    bool? destroyMySprint,
    bool? destroyMyBlock,
    bool? destroyOppSprint,
    bool? destroyOppBlock,
  }) {
    return BoardEffects(
      mySprintDelta: mySprintDelta ?? this.mySprintDelta,
      myBlockDelta: myBlockDelta ?? this.myBlockDelta,
      oppSprintDelta: oppSprintDelta ?? this.oppSprintDelta,
      oppBlockDelta: oppBlockDelta ?? this.oppBlockDelta,
      destroyMySprint: destroyMySprint ?? this.destroyMySprint,
      destroyMyBlock: destroyMyBlock ?? this.destroyMyBlock,
      destroyOppSprint: destroyOppSprint ?? this.destroyOppSprint,
      destroyOppBlock: destroyOppBlock ?? this.destroyOppBlock,
    );
  }

  static BoardEffects applyTrick(BoardEffects base, TrickSpec spec) {
    var b = base;
    bool onMe = spec.side == TargetSide.me;

    int addS = spec.addToSprinter - spec.removeFromSprinter;
    int addB = spec.addToBlocker - spec.removeFromBlocker;

    if (onMe) {
      b = b.copyWith(
        mySprintDelta: b.mySprintDelta + addS,
        myBlockDelta: b.myBlockDelta + addB,
        destroyMySprint: b.destroyMySprint || spec.destroySprinter,
        destroyMyBlock: b.destroyMyBlock || spec.destroyBlocker,
      );
    } else {
      b = b.copyWith(
        oppSprintDelta: b.oppSprintDelta + addS,
        oppBlockDelta: b.oppBlockDelta + addB,
        destroyOppSprint: b.destroyOppSprint || spec.destroySprinter,
        destroyOppBlock: b.destroyOppBlock || spec.destroyBlocker,
      );
    }
    return b;
  }
}

// Risultato di un round
class RoundResult {
  final Terrain terrain;
  final SecretChoice me;
  final SecretChoice opp;
  final int delta; // (mySprint - oppBlock)
  const RoundResult({
    required this.terrain,
    required this.me,
    required this.opp,
    required this.delta,
  });
}
