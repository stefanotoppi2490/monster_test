import 'package:flutter/material.dart';
import 'package:monster/core/models/models.dart';

class FlipCardFace extends StatelessWidget {
  final GameCard card;
  final Terrain terrain;
  const FlipCardFace({super.key, required this.card, required this.terrain});

  @override
  Widget build(BuildContext context) {
    final isSprint = card.kind == CardKind.sprint;
    final value = card.valueOn(terrain);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSprint
              ? const [Color(0xFFA0A7FF), Color(0xFF6A72E8)]
              : const [Color(0xFF61E3D7), Color(0xFF2FBCAF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            isSprint ? 'SPRINT' : 'BLOCCO',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            card.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${terrain.label}: $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
