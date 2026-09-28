import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/day_weather.dart';
import '../services/map_ambiance_service.dart';

/// Calque atmosphérique animé jour / crépuscule / nuit au-dessus de la carte.
/// Inspiré directement de MapAmbianceOverlay dans hellobarber_frontend.
/// 100% IgnorePointer : ne bloque aucun clic ni geste sur la carte.
class MapAmbianceOverlay extends StatefulWidget {
  const MapAmbianceOverlay({
    super.key,
    required this.ambiance,
    this.weather,
    this.topInset = 0,
  });

  final MapAmbiance ambiance;
  final DayWeather? weather;
  final double topInset;

  @override
  State<MapAmbianceOverlay> createState() => _MapAmbianceOverlayState();
}

class _MapAmbianceOverlayState extends State<MapAmbianceOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _twinkleController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ambiance = widget.ambiance;
    final weather = widget.weather;
    final isStormy = weather != null && weather.weatherCode >= 95;

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Stack(
          key: ValueKey('${ambiance.phase}_$isStormy'),
          fit: StackFit.expand,
          children: [
            // 1. Teinte d'ambiance globale (subtile, ne bloque pas la carte)
            if (ambiance.ambientOverlay > 0)
              AnimatedBuilder(
                animation: _breathController,
                builder: (context, child) {
                  final pulse = 0.85 + _breathController.value * 0.25;
                  return ColoredBox(
                    color: ambiance.ambientColor.withValues(
                      alpha: (ambiance.ambientOverlay * pulse).clamp(0.0, 0.4),
                    ),
                  );
                },
              ),

            // 2. Dégradé de ciel en haut de carte
            if (ambiance.skyGradient.isNotEmpty)
              _AnimatedSkyGradient(
                colors: ambiance.skyGradient,
                opacity: ambiance.skyGradientOpacity,
                topInset: widget.topInset,
                breath: _breathController,
              ),

            // 3. Étoiles scintillantes la nuit (subtiles, seulement dans la partie haute)
            if (ambiance.showStars && !isStormy)
              AnimatedBuilder(
                animation: _twinkleController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _StarFieldPainter(
                      twinkle: _twinkleController.value,
                      topInset: widget.topInset,
                    ),
                  );
                },
              ),

            // 4. Lune ou Soleil stylisé en haut à droite
            if (ambiance.showMoon && !isStormy)
              Positioned(
                top: widget.topInset + 64,
                right: 28,
                child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF9C4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFF9C4).withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (ambiance.showSun)
              Positioned(
                top: widget.topInset + 64,
                right: 28,
                child: Opacity(
                  opacity: 0.75,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ambiance.phase == MapAmbiancePhase.goldenHour
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFFFFEE58),
                      boxShadow: [
                        BoxShadow(
                          color: (ambiance.phase == MapAmbiancePhase.goldenHour
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFFFEE58))
                              .withValues(alpha: 0.45),
                          blurRadius: 20,
                          spreadRadius: 6,
                        ),
                      ],
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

class _AnimatedSkyGradient extends StatelessWidget {
  const _AnimatedSkyGradient({
    required this.colors,
    required this.opacity,
    required this.topInset,
    required this.breath,
  });

  final List<Color> colors;
  final double opacity;
  final double topInset;
  final Animation<double> breath;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breath,
      builder: (context, _) {
        final liveOpacity = (opacity * (0.85 + breath.value * 0.25)).clamp(0.0, 1.0);
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset + 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors
                    .map((c) => c.withValues(alpha: (c.a * liveOpacity).clamp(0.0, 1.0)))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({
    required this.twinkle,
    required this.topInset,
  });

  final double twinkle;
  final double topInset;

  static final List<math.Point<double>> _stars = [
    const math.Point(0.12, 0.06),
    const math.Point(0.25, 0.12),
    const math.Point(0.38, 0.04),
    const math.Point(0.48, 0.16),
    const math.Point(0.62, 0.08),
    const math.Point(0.74, 0.15),
    const math.Point(0.85, 0.05),
    const math.Point(0.92, 0.18),
    const math.Point(0.18, 0.22),
    const math.Point(0.55, 0.24),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final maxH = topInset + 180;

    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final x = s.x * size.width;
      final y = topInset + (s.y * (maxH - topInset));
      final factor = (math.sin(twinkle * math.pi * 2 + i) + 1.0) / 2.0;
      final radius = 1.0 + factor * 0.8;
      paint.color = Colors.white.withValues(alpha: 0.25 + factor * 0.55);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.twinkle != twinkle;
}
