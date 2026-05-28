import 'package:flutter/material.dart';
import '../theme.dart';

class XpProgressBar extends StatelessWidget {
  final int xp;
  final int level;
  final int streak;
  final bool compact;

  const XpProgressBar({
    super.key,
    required this.xp,
    required this.level,
    required this.streak,
    this.compact = false,
  });

  int get xpInLevel => xp % 100;
  double get progress => xpInLevel / 100.0;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Row(
      children: [
        _LevelBadge(level: level, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Niveau $level',
                    style: const TextStyle(
                      color: VoyagoColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$xpInLevel / 100 XP',
                    style: const TextStyle(
                      color: VoyagoColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: VoyagoColors.cardBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    VoyagoColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (streak > 0) ...[
          const SizedBox(width: 12),
          _StreakBadge(streak: streak),
        ],
      ],
    );
  }

  Widget _buildFull(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoyagoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VoyagoColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LevelBadge(level: level, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau $level',
                      style: const TextStyle(
                        color: VoyagoColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$xpInLevel / 100 XP',
                      style: const TextStyle(
                        color: VoyagoColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0) _StreakBadge(streak: streak),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: VoyagoColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(
                VoyagoColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${100 - xpInLevel} XP pour le niveau ${level + 1}',
            style: const TextStyle(color: VoyagoColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final double size;

  const _LevelBadge({required this.level, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: VoyagoColors.primary,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: VoyagoColors.yellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VoyagoColors.yellow.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
              color: VoyagoColors.yellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
