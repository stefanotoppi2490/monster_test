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
enum CardKind { sprint, block, instant }

// Carta base con valori per terreno (0..10)
class GameCard {
  final String id;
  final String name;
  final CardKind kind;
  final Map<Terrain, int> valueByTerrain; // per le instant puoi mettere tutto 0
  final int manaCost;

  const GameCard({
    required this.id,
    required this.name,
    required this.kind,
    required this.valueByTerrain,
    required this.manaCost,
  });

  int valueOn(Terrain t) => valueByTerrain[t] ?? 0;

  GameCard copyWith({String? id}) => GameCard(
    id: id ?? this.id,
    name: name,
    kind: kind,
    valueByTerrain: valueByTerrain,
    manaCost: manaCost,
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

// Scelte segrete di un giocatore nel round
class SecretChoice {
  final GameCard? sprint;
  final GameCard? block;

  const SecretChoice({this.sprint, this.block});

  bool get isEmpty => sprint == null && block == null;
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
