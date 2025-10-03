import 'dart:math';

import 'package:monster/core/config.dart';
import 'package:monster/core/factory_deck.dart';
import 'package:monster/core/models/models.dart';

class GameRepo {
  final _rng = Random();

  (Deck, List<GameCard>) draw(Deck deck, int n) => deck.draw(n);

  Deck starterDeck() => buildStarterDeck35();

  /// Genera una lista di terreni lunga `rounds`, random,
  /// con il vincolo: ogni terreno può comparire al massimo `kMaxSameTerrain` volte.
  List<Terrain> randomTerrainOrder(int rounds) {
    final clamped = rounds.clamp(1, kMaxRounds);
    final counts = {for (var t in Terrain.values) t: 0};
    final order = <Terrain>[];

    while (order.length < clamped) {
      final shuffled = [...Terrain.values]..shuffle(_rng);
      Terrain? picked;
      for (final t in shuffled) {
        if ((counts[t] ?? 0) < kMaxSameTerrain) {
          picked = t;
          break;
        }
      }
      picked ??= shuffled.first; // fallback impossibile, ma per sicurezza
      counts[picked] = (counts[picked] ?? 0) + 1;
      order.add(picked);
    }
    return order;
  }
}
