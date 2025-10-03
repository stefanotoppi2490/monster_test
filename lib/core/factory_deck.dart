import 'dart:math';
import 'package:monster/core/models/models.dart';

/// ---- COSTO MANA SU 4 TERRENI ----------------------------------------------
const int kMinManaCost = 1;
const int kMaxManaCost = 10;

const double kPeakWeight = 0.65;
const double kMeanWeight = 0.35;

const double kSprintMultiplier = 1.00;
const double kBlockMultiplier = 0.85;
// per le instant, per ora un costo base leggero:
const int kInstantBaseCost = 2;

const double kScale = 0.45;

int _finalizeCost(double x) =>
    x.isNaN ? kMinManaCost : x.ceil().clamp(kMinManaCost, kMaxManaCost);

int _computeManaCost4({
  required bool isSprint,
  required int terra,
  required int mare,
  required int aria,
  required int sabbia,
}) {
  final vals = [terra, mare, aria, sabbia];
  final peak = vals.reduce(max).toDouble();
  final mean = vals.reduce((a, b) => a + b) / vals.length;

  final raw = kPeakWeight * peak + kMeanWeight * mean;
  final mult = isSprint ? kSprintMultiplier : kBlockMultiplier;

  return _finalizeCost(raw * mult * kScale);
}

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

GameCard _i(String name, {required int cost}) {
  // placeholder: nessun valore per terreno (tutti 0). Effetti li metteremo dopo.
  return GameCard(
    id: name,
    name: name,
    kind: CardKind.instant,
    manaCost: cost.clamp(1, 10),
    valueByTerrain: const {
      Terrain.asfalto: 0,
      Terrain.acqua: 0,
      Terrain.sabbia: 0,
      Terrain.fango: 0,
    },
  );
}

/// ---- SEED 35 CARTE ---------------------------------------------------------
/// 15 sprint, 15 block, 5 instant (placeholder)
/// ---- SEED 35 CARTE ---------------------------------------------------------
/// Remap valori: terra→asfalto, mare→acqua, sabbia→sabbia, aria→fango.
/// Mana COST fissato manualmente carta per carta.
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

  // 5 sprint “beta” per arrivare a 15 sprint (stesse stats, costo simile)
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

  // 5 block “beta” per arrivare a 15 block
  _b('Muraglia d’Ossidiana', 7, 0, 0, 0, 4),
  _b('Onda Infranta', 0, 7, 0, 0, 4),
  _b('Vento Spezzante', 0, 0, 0, 7, 4),
  _b('Collasso di Sabbia', 0, 0, 7, 0, 4),
  _b('Baluardo Antico', 5, 0, 0, 0, 3),

  // 5 instant (placeholder con costi fissi)
  _i('Scatto Istantaneo', cost: 2),
  _i('Raffica Istantanea', cost: 2),
  _i('Barriera Immediata', cost: 2),
  _i('Finta Fulminea', cost: 1),
  _i('Sgambetto', cost: 3),
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
