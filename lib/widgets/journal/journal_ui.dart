import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';

/// Briques visuelles du journal : verre dépoli, lueur dorée des badges, métriques.

/// Carte en verre dépoli sur fond sombre (cœur visuel du journal).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final bool glow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.borderColor,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 28, offset: const Offset(0, 12)),
          if (glow) BoxShadow(color: VoyagoColors.yellow.withValues(alpha: 0.18), blurRadius: 24, spreadRadius: -4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: VoyagoColors.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor ?? VoyagoColors.cardBorder.withValues(alpha: 0.9)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Petite pastille (statut, créneau, humeur…).
class JournalPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool dot;

  const JournalPill({super.key, required this.label, required this.color, this.icon, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile de métrique (distance, lieux visités, pépites, XP).
class JournalMetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const JournalMetricTile({super.key, required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VoyagoColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VoyagoColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: VoyagoColors.muted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color == VoyagoColors.yellow ? VoyagoColors.yellow : VoyagoColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icône associée au badge renvoyé par le serveur.
IconData journalBadgeIcon(String key) {
  switch (key) {
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'account_balance':
      return Icons.account_balance_rounded;
    case 'palette':
      return Icons.palette_rounded;
    case 'forest':
      return Icons.forest_rounded;
    case 'beach_access':
      return Icons.beach_access_rounded;
    case 'nightlife':
      return Icons.nightlife_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_rounded;
    case 'hiking':
      return Icons.hiking_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'diamond':
      return Icons.diamond_rounded;
    case 'directions_walk':
      return Icons.directions_walk_rounded;
    default:
      return Icons.workspace_premium_rounded;
  }
}

/// Moment de la journée selon l'ordre de l'étape.
({String label, Color color}) journalSlot(int order, int count) {
  if (order <= 1) return (label: 'MATIN', color: VoyagoColors.yellow);
  if (order == 2) return (label: 'MIDI', color: VoyagoColors.orange);
  if (order >= count && count >= 4) return (label: 'SOIRÉE', color: const Color(0xFFB39DFF));
  if (order == 3) return (label: 'APRÈS-MIDI', color: VoyagoColors.blue);
  return (label: 'FIN DE JOURNÉE', color: const Color(0xFFB39DFF));
}

/// « 1 – 3 sept. 2026 » à partir des dates du voyage.
String journalDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return '';
  final d = DateFormat('d MMM', 'fr');
  final y = DateFormat('d MMM yyyy', 'fr');
  if (start == null) return y.format(end!);
  if (end == null || end.isAtSameMomentAs(start)) return y.format(start);
  return '${d.format(start)} – ${y.format(end)}';
}
