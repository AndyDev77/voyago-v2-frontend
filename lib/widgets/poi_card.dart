import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/poi.dart';
import '../theme.dart';

class PoiCard extends StatelessWidget {
  final POI poi;
  final int index;

  const PoiCard({super.key, required this.poi, required this.index});

  String get _durationLabel {
    if (poi.durationMinutes < 60) return '${poi.durationMinutes} min';
    final h = poi.durationMinutes ~/ 60;
    final m = poi.durationMinutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: VoyagoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VoyagoColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (poi.imageUrl != null && poi.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: poi.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildPlaceholder(),
                errorWidget: (_, __, ___) => _buildPlaceholder(),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: _buildPlaceholder(),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order number + name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: VoyagoColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        poi.name,
                        style: const TextStyle(
                          color: VoyagoColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  poi.description,
                  style: const TextStyle(
                    color: VoyagoColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Chip(
                      icon: '🏷',
                      label: poi.category,
                      color: VoyagoColors.blue.withOpacity(0.15),
                      textColor: VoyagoColors.blue,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: '⏱',
                      label: _durationLabel,
                      color: VoyagoColors.primary.withOpacity(0.15),
                      textColor: VoyagoColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: VoyagoColors.cardBorder,
      child: const Center(
        child: Text('📍', style: TextStyle(fontSize: 32)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final Color textColor;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
