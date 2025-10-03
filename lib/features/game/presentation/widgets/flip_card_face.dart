import 'package:flutter/material.dart';
import 'package:monster/core/models/models.dart';

class FlipCardFace extends StatelessWidget {
  final GameCard card;
  final Terrain terrain;
  const FlipCardFace({super.key, required this.card, required this.terrain});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          card.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback se l'immagine non viene trovata
            final isSprint = card.kind == CardKind.sprint;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSprint
                      ? const [Color(0xFFA0A7FF), Color(0xFF6A72E8)]
                      : const [Color(0xFF61E3D7), Color(0xFF2FBCAF)],
                ),
              ),
              child: Center(
                child: Text(
                  card.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
