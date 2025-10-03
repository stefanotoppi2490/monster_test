import 'dart:math';
import 'package:monster/core/models/models.dart';

/// ---- HELPERS ---------------------------------------------------------------
GameCard _s(
  String name,
  int asfalto,
  int acqua,
  int sabbia,
  int fango,
  int cost,
) {
  return GameCard(
    id: name,
    name: name,
    kind: CardKind.sprint,
    manaCost: cost.clamp(1, 10),
    valueByTerrain: {
      Terrain.asfalto: asfalto,
      Terrain.acqua: acqua,
      Terrain.sabbia: sabbia,
      Terrain.fango: fango,
    },
  );
}

GameCard _b(
  String name,
  int asfalto,
  int acqua,
  int sabbia,
  int fango,
  int cost,
) {
  return GameCard(
    id: name,
    name: name,
    kind: CardKind.block,
    manaCost: cost.clamp(1, 10),
    valueByTerrain: {
      Terrain.asfalto: asfalto,
      Terrain.acqua: acqua,
      Terrain.sabbia: sabbia,
      Terrain.fango: fango,
    },
  );
}

GameCard _t(
  // ⬅️ Trick
  String name, {
  required int cost,
  required TrickSpec spec,
}) {
  return GameCard(
    id: name,
    name: name,
    kind: CardKind.trick,
    manaCost: cost.clamp(1, 10),
    valueByTerrain: const {
      Terrain.asfalto: 0,
      Terrain.acqua: 0,
      Terrain.sabbia: 0,
      Terrain.fango: 0,
    },
    trick: spec,
  );
}

/// ---- SEED 35 CARTE ---------------------------------------------------------
List<GameCard> _seed35() => [
  // 10 sprint “uniche”
  _s('Leviatano', 0, 9, 0, 0, 6),
  _s('Zombie Abissale', 2, 0, 0, 1, 2),
  _s('Falco Ionico', 0, 0, 1, 8, 5),
  _s('Viverna delle Dune', 0, 0, 9, 2, 6),
  _s('Cavaliere delle Tempeste', 0, 0, 2, 7, 5),
  _s('Troll della Terra', 8, 0, 0, 0, 5),
  _s('Sirena degli Abissi', 0, 7, 0, 0, 5),
  _s('Mirmidone', 6, 0, 2, 1, 4),
  _s('Carcassa Errante', 4, 0, 0, 1, 3),
  _s('Grifone', 0, 0, 0, 7, 4),

  // 5 sprint “beta”
  _s('Kraken Abissale', 0, 9, 0, 0, 6),
  _s('Arpia Fulminea', 0, 0, 1, 8, 5),
  _s('Serpente delle Dune', 0, 0, 9, 2, 6),
  _s('Guerriero del Tuono', 0, 0, 2, 7, 5),
  _s('Gigante di Pietra', 8, 0, 0, 0, 5),

  // 10 block “uniche”
  _b('Argine Granitico', 7, 0, 0, 0, 4),
  _b('Marea Contraria', 0, 7, 0, 0, 4),
  _b('Turbine Aereo', 0, 0, 0, 7, 4),
  _b('Duna Mobile', 0, 0, 7, 0, 4),
  _b('Bastione', 5, 0, 0, 0, 3),
  _b('Frangiflutti', 0, 5, 0, 0, 3),
  _b('Controvento', 0, 0, 0, 5, 3),
  _b('Sabbie Mobili', 0, 0, 5, 0, 3),
  _b('Argine Antico', 6, 0, 0, 0, 3),
  _b('Vortice', 0, 0, 0, 6, 3),

  // 5 block “beta”
  _b('Muraglia d’Ossidiana', 7, 0, 0, 0, 4),
  _b('Onda Infranta', 0, 7, 0, 0, 4),
  _b('Vento Spezzante', 0, 0, 0, 7, 4),
  _b('Collasso di Sabbia', 0, 0, 7, 0, 4),
  _b('Baluardo Antico', 5, 0, 0, 0, 3),

  // 5 TRICK (ex “instant”) — esempi concreti
  // Aggiungi +2 al tuo Sprinter
  _t(
    'Nitro Istantanea',
    cost: 2,
    spec: TrickSpec(side: TargetSide.me, addToSprinter: 2),
  ),
  // Aggiungi +2 al tuo Blocker
  _t(
    'Scudo Arcano',
    cost: 2,
    spec: TrickSpec(side: TargetSide.me, addToBlocker: 2),
  ),
  // Rimuovi 2 allo Sprinter avversario
  _t(
    'Trappola di Sabbia',
    cost: 2,
    spec: TrickSpec(side: TargetSide.opp, removeFromSprinter: 2),
  ),
  // Rimuovi 2 al Blocker avversario e +1 al tuo Sprinter
  _t(
    'Finta Letale',
    cost: 3,
    spec: TrickSpec(side: TargetSide.opp, removeFromBlocker: 2),
  ),
  // Distruggi il Blocker avversario
  _t(
    'Annullamento Totale',
    cost: 4,
    spec: TrickSpec(side: TargetSide.opp, destroyBlocker: true),
  ),
];

Deck buildStarterDeck35() {
  final list = _seed35();
  final out = <GameCard>[];
  int i = 0;
  for (final c in list) {
    out.add(c.copyWith(id: '${c.id}#$i'));
    i++;
  }
  return Deck(out).shuffled(Random());
}
