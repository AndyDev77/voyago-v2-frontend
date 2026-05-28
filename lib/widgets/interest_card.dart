import 'package:flutter/material.dart';
import '../models/interest.dart';
import '../theme.dart';

class InterestCard extends StatelessWidget {
  final Interest interest;
  final double dragOffset;
  final bool isTop;

  const InterestCard({
    super.key,
    required this.interest,
    this.dragOffset = 0,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = isTop ? (dragOffset / 300.0) : 0.0;
    final showLike = isTop && dragOffset > 30;
    final showNope = isTop && dragOffset < -30;

    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: screenWidth * 0.85,
        height: 400,
        decoration: BoxDecoration(
          color: VoyagoColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: showLike
                ? VoyagoColors.primary
                : showNope
                    ? VoyagoColors.coral
                    : VoyagoColors.cardBorder,
            width: showLike || showNope ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Emoji
                  Text(
                    interest.emoji,
                    style: const TextStyle(fontSize: 80),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    interest.title,
                    style: const TextStyle(
                      color: VoyagoColors.text,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    interest.description,
                    style: const TextStyle(
                      color: VoyagoColors.muted,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Swipe indicators
            if (showLike)
              Positioned(
                top: 24,
                left: 24,
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: VoyagoColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✓ J\'AIME',
                      style: TextStyle(
                        color: VoyagoColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (showNope)
              Positioned(
                top: 24,
                right: 24,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: VoyagoColors.coral, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✗ PASSER',
                      style: TextStyle(
                        color: VoyagoColors.coral,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
