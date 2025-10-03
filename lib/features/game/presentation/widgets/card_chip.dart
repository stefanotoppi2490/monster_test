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
    this.width = 180,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
        border: Border.all(color: Colors.white24),
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
