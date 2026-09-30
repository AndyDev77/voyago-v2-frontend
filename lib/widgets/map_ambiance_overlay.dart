import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/day_weather.dart';
import '../services/map_ambiance_service.dart';

/// Calque atmosphérique animé dynamique : jour / crépuscule / nuit / lever du jour au-dessus de la carte.
/// Inspiré directement de MapAmbianceOverlay dans hellobarber_frontend.
/// 100% IgnorePointer : ne bloque aucun clic ni geste sur la carte.
class MapAmbianceOverlay extends StatefulWidget {
  const MapAmbianceOverlay({
    super.key,
    required this.ambiance,
    this.weather,
    this.topInset = 0,
    this.forceDay = false,
  });

  final MapAmbiance ambiance;
  final DayWeather? weather;
  final double topInset;
  final bool forceDay;

  @override
  State<MapAmbianceOverlay> createState() => _MapAmbianceOverlayState();
}

class _MapAmbianceOverlayState extends State<MapAmbianceOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _twinkleController;
  late final AnimationController _celestialController;

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

    _celestialController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _twinkleController.dispose();
    _celestialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ambiance = widget.ambiance;
    final weather = widget.weather;
    final forceDay = widget.forceDay;
    final isStormy = weather != null && weather.weatherCode >= 95;

    // Si le mode plein jour est forcé manuellement, on désactive les calques sombres de nuit
    final showStars = !forceDay && ambiance.showStars && !isStormy;
    final showMoon = !forceDay && ambiance.showMoon && !isStormy;
    final showSun = forceDay || ambiance.showSun;

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Stack(
          key: ValueKey('${ambiance.phase}_${forceDay}_$isStormy'),
          fit: StackFit.expand,
          children: [
            // 1. Teinte d'ambiance globale (subtile, ne bloque pas la carte)
            if (!forceDay && ambiance.ambientOverlay > 0)
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
            if (!forceDay && ambiance.skyGradient.isNotEmpty)
              _AnimatedSkyGradient(
                colors: ambiance.skyGradient,
                opacity: ambiance.skyGradientOpacity,
                topInset: widget.topInset,
                breath: _breathController,
              ),

            // 3. Étoiles scintillantes la nuit ou au crépuscule
            if (showStars)
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

            // 4. Astre céleste stylisé (Lune ou Soleil) positionné élégamment dans l'espace dégagé de la carte
            if (showMoon)
              AnimatedBuilder(
                animation: _celestialController,
                builder: (context, _) {
                  final float = math.sin(_celestialController.value * math.pi * 2) * 4;
                  return Positioned(
                    top: widget.topInset + 116 + float,
                    right: 20,
                    child: _CelestialMoon(
                      isTwilight: ambiance.phase == MapAmbiancePhase.twilight,
                    ),
                  );
                },
              )
            else if (showSun)
              AnimatedBuilder(
                animation: _celestialController,
                builder: (context, _) {
                  final float = math.sin(_celestialController.value * math.pi * 2) * 4;
                  return Positioned(
                    top: widget.topInset + 116 + float,
                    right: 20,
                    child: _CelestialSun(phase: ambiance.phase),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CelestialSun extends StatelessWidget {
  final MapAmbiancePhase phase;

  const _CelestialSun({required this.phase});

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    Color glowColor;
    double size = 32;

    switch (phase) {
      case MapAmbiancePhase.dawn:
        primaryColor = const Color(0xFFFFAB91); // Rose aurore doux
        glowColor = const Color(0xFFFFCC80);
        size = 30;
        break;
      case MapAmbiancePhase.goldenHour:
        primaryColor = const Color(0xFFFF9800); // Or orangé éclatant
        glowColor = const Color(0xFFFFB74D);
        size = 34;
        break;
      case MapAmbiancePhase.day:
      default:
        primaryColor = const Color(0xFFFFEE58); // Jaune soleil pur
        glowColor = const Color(0xFFFFF59D);
        size = 32;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white,
            primaryColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.55),
            blurRadius: 18,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 28,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _CelestialMoon extends StatelessWidget {
  final bool isTwilight;

  const _CelestialMoon({this.isTwilight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.2),
          colors: [
            const Color(0xFFFFFDE7),
            isTwilight ? const Color(0xFFE0E0E0) : const Color(0xFFE0F7FA),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0F7FA).withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
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
          height: topInset + 220,
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
    const math.Point(0.08, 0.05),
    const math.Point(0.18, 0.10),
    const math.Point(0.28, 0.04),
    const math.Point(0.38, 0.14),
    const math.Point(0.50, 0.06),
    const math.Point(0.62, 0.12),
    const math.Point(0.72, 0.05),
    const math.Point(0.82, 0.15),
    const math.Point(0.92, 0.08),
    const math.Point(0.12, 0.20),
    const math.Point(0.44, 0.22),
    const math.Point(0.78, 0.24),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final maxH = topInset + 190;

    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final x = s.x * size.width;
      final y = topInset + (s.y * (maxH - topInset));
      final factor = (math.sin(twinkle * math.pi * 2 + i) + 1.0) / 2.0;
      final radius = 1.0 + factor * 0.9;
      paint.color = Colors.white.withValues(alpha: 0.20 + factor * 0.60);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.twinkle != twinkle;
}
