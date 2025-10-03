import 'package:flutter/material.dart';
import 'package:monster/core/models/models.dart';

class CardChip extends StatelessWidget {
  final GameCard card;
  final Terrain terrain;

  /// Puoi riusarla ovunque; in mano usi 120x160, nello slot 110x150.
  final double width;
  final double height;

  const CardChip({
    super.key,
    required this.card,
    required this.terrain,
    this.width = 120,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final isSprint = card.kind == CardKind.sprint;
    final value = card.valueOn(terrain);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSprint
              ? const [Color(0xFF7B88FF), Color(0xFF5158C8)]
              : const [Color(0xFF3AD4C5), Color(0xFF249E93)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(8), // più stretto per rientrare
      child: FittedBox(
        fit: BoxFit.scaleDown, // evita qualsiasi micro-overflow
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // lascia respiro interno per testi/badge
            maxWidth: width - 16,
            maxHeight: height - 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSprint ? 'SPRINT' : 'BLOCCO',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: (width - 20).clamp(80, double.infinity),
                child: Text(
                  card.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Valore ${terrain.label}: $value',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 2),
              Text(
                'Mana ${card.manaCost}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
