import 'package:flutter/material.dart';
import 'package:monster/core/config.dart';
import 'package:monster/core/models/models.dart';

class CardChip extends StatelessWidget {
  final GameCard card;
  final Terrain terrain;

  /// Dimensioni fisse delle carte dal config
  final double width;
  final double height;

  const CardChip({
    super.key,
    required this.card,
    required this.terrain,
    this.width = kCardWidth,
    this.height = kCardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        child: Image.asset(
          card.imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback se l'immagine non viene trovata
            final isSprint = card.kind == CardKind.sprint;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSprint
                      ? const [Color(0xFF7B88FF), Color(0xFF5158C8)]
                      : const [Color(0xFF3AD4C5), Color(0xFF249E93)],
                ),
              ),
              child: Center(
                child: Text(
                  card.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
