import 'package:flutter/material.dart';
import '../theme.dart';

class BadgeGrid extends StatelessWidget {
  final List<String> earnedBadges;
  final List<Map<String, dynamic>> allBadges;

  const BadgeGrid({
    super.key,
    required this.earnedBadges,
    required this.allBadges,
  });

  @override
  Widget build(BuildContext context) {
    if (allBadges.isEmpty && earnedBadges.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aucun badge disponible',
          style: TextStyle(color: VoyagoColors.muted),
        ),
      );
    }

    // If we have allBadges data, use it; otherwise display earned badges
    final displayBadges = allBadges.isNotEmpty
        ? allBadges
        : earnedBadges
            .map((b) => {'id': b, 'name': b, 'emoji': '🏆', 'description': ''})
            .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: displayBadges.length,
      itemBuilder: (context, index) {
        final badge = displayBadges[index];
        final badgeId = badge['id']?.toString() ?? '';
        final isEarned = earnedBadges.contains(badgeId);
        final emoji = badge['emoji']?.toString() ?? '🏆';
        final name = badge['name']?.toString() ?? badgeId;

        return _BadgeItem(
          emoji: emoji,
          name: name,
          isEarned: isEarned,
          onTap: () => _showBadgeDetails(context, badge, isEarned),
        );
      },
    );
  }

  void _showBadgeDetails(
    BuildContext context,
    Map<String, dynamic> badge,
    bool isEarned,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VoyagoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge['emoji']?.toString() ?? '🏆',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              badge['name']?.toString() ?? '',
              style: const TextStyle(
                color: VoyagoColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (badge['description'] != null)
              Text(
                badge['description'].toString(),
                style: const TextStyle(color: VoyagoColors.muted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isEarned
                    ? VoyagoColors.primary.withOpacity(0.2)
                    : VoyagoColors.cardBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isEarned ? '✓ Obtenu' : '🔒 Non obtenu',
                style: TextStyle(
                  color: isEarned ? VoyagoColors.primary : VoyagoColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String emoji;
  final String name;
  final bool isEarned;
  final VoidCallback onTap;

  const _BadgeItem({
    required this.emoji,
    required this.name,
    required this.isEarned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isEarned
                    ? VoyagoColors.primary.withOpacity(0.15)
                    : VoyagoColors.cardBorder,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEarned
                      ? VoyagoColors.primary.withOpacity(0.4)
                      : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: isEarned ? VoyagoColors.text : VoyagoColors.muted,
                fontSize: 10,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
