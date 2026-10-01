import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/day_weather.dart';
import '../services/map_ambiance_service.dart';
import 'map_weather_effects.dart';

/// Calque atmosphérique animé dynamique : jour / crépuscule / nuit / lever du jour + météo réelle (pluie, nuages, orage, neige).
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
  AnimationController? _cloudController;

  void _ensureCloudController() {
    _cloudController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 38),
    )..repeat();
  }

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

    _ensureCloudController();
  }

  @override
  void reassemble() {
    super.reassemble();
    _ensureCloudController();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _twinkleController.dispose();
    _celestialController.dispose();
    _cloudController?.dispose();
    super.dispose();
  }

  List<Color> _skyColorsFor(MapAmbiance ambiance, DayWeather? weather) {
    if (weather == null) return ambiance.skyGradient;

    if (weather.isThunderstorm) {
      return const [
        Color(0xFF37474F),
        Color(0xFF546E7A),
        Color(0x00263238),
      ];
    }
    if (weather.hasPrecipitation) {
      return const [
        Color(0xFF546E7A),
        Color(0xFF78909C),
        Color(0x00455A64),
      ];
    }
    if (weather.isFoggy) {
      return const [
        Color(0xFFCFD8DC),
        Color(0xFFECEFF1),
        Color(0x00FFFFFF),
      ];
    }
    if (weather.weatherCode >= 2) {
      return const [
        Color(0xFF90A4AE),
        Color(0xFFB0BEC5),
        Color(0x00CFD8DC),
      ];
    }
    return ambiance.skyGradient;
  }

  @override
  Widget build(BuildContext context) {
    _ensureCloudController();
    final ambiance = widget.ambiance;
    final weather = widget.weather;
    final forceDay = widget.forceDay;

    final hasRain = weather?.hasPrecipitation ?? false;
    final isCloudy = weather?.showClouds ?? false;
    final isStormy = weather?.isThunderstorm ?? false;

    // Étoiles et astres masqués en cas de pluie / orage violent
    final showStars = !forceDay && ambiance.showStars && !hasRain && !isCloudy;
    final showMoon = !forceDay && ambiance.showMoon && !hasRain && (weather?.weatherCode ?? 0) <= 1;
    final showSun = (forceDay || ambiance.showSun) && !hasRain && (weather?.weatherCode ?? 0) <= 1;

    final skyColors = _skyColorsFor(ambiance, weather);

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Stack(
          key: ValueKey('${ambiance.phase}_${forceDay}_${weather?.weatherCode}'),
          fit: StackFit.expand,
          children: [
            // 1. Teinte d'ambiance globale (subtile, ne bloque pas la carte)
            if (!forceDay && (ambiance.ambientOverlay > 0 || hasRain))
              AnimatedBuilder(
                animation: _breathController,
                builder: (context, child) {
                  final pulse = 0.85 + _breathController.value * 0.25;
                  final baseColor = hasRain ? const Color(0xFF263238) : ambiance.ambientColor;
                  final overlayAlpha = hasRain ? 0.22 : ambiance.ambientOverlay;
                  return ColoredBox(
                    color: baseColor.withValues(
                      alpha: (overlayAlpha * pulse).clamp(0.0, 0.45),
                    ),
                  );
                },
              ),

            // 2. Dégradé de ciel en haut de carte adapté à la météo
            if (!forceDay && skyColors.isNotEmpty)
              _AnimatedSkyGradient(
                colors: skyColors,
                opacity: hasRain ? 0.75 : ambiance.skyGradientOpacity,
                topInset: widget.topInset,
                breath: _breathController,
              ),

            // 3. Nuages dérivants atmosphériques (comme hellobarber)
            if (isCloudy || hasRain)
              _DriftingCloudsLayer(
                topInset: widget.topInset,
                animation: _cloudController!,
                grey: hasRain || (weather?.weatherCode ?? 0) >= 2,
              ),

            // 4. Étoiles scintillantes la nuit ou au crépuscule
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

            // 5. Astre céleste stylisé (Lune ou Soleil)
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

            // 6. Effets météo en temps réel (Pluie qui tombe, Neige, Brume, Éclairs)
            if (weather != null && (weather.hasPrecipitation || weather.isFoggy || isStormy))
              MapWeatherEffectsLayer(
                weather: weather,
                topInset: widget.topInset,
              ),
          ],
        ),
      ),
    );
  }
}

class _DriftingCloudsLayer extends StatelessWidget {
  const _DriftingCloudsLayer({
    required this.topInset,
    required this.animation,
    this.grey = false,
  });

  final double topInset;
  final Animation<double> animation;
  final bool grey;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final screenWidth = MediaQuery.of(context).size.width;
        return Stack(
          children: [
            _CloudPuff(
              top: topInset + 20,
              left: -80 + t * (screenWidth + 160),
              scale: 1.0,
              grey: grey,
              opacity: grey ? 0.65 : 0.45,
            ),
            _CloudPuff(
              top: topInset + 55,
              left: -120 + ((t + 0.38) % 1) * (screenWidth + 180),
              scale: 0.75,
              grey: grey,
              opacity: grey ? 0.50 : 0.35,
            ),
            _CloudPuff(
              top: topInset + 35,
              left: -60 + ((t + 0.68) % 1) * (screenWidth + 140),
              scale: 0.58,
              grey: grey,
              opacity: grey ? 0.45 : 0.30,
            ),
          ],
        );
      },
    );
  }
}

class _CloudPuff extends StatelessWidget {
  const _CloudPuff({
    required this.top,
    required this.left,
    required this.scale,
    required this.opacity,
    this.grey = false,
  });

  final double top;
  final double left;
  final double scale;
  final double opacity;
  final bool grey;

  Widget _cloudCircle(double size, Color color, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = grey ? const Color(0xFFCFD8DC) : Colors.white;
    return Positioned(
      top: top,
      left: left,
      child: Transform.scale(
        scale: scale,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cloudCircle(34, color, opacity),
            Transform.translate(
              offset: const Offset(-12, 6),
              child: _cloudCircle(26, color, opacity * 0.95),
            ),
            Transform.translate(
              offset: const Offset(-18, 0),
              child: _cloudCircle(28, color, opacity * 0.9),
            ),
            Transform.translate(
              offset: const Offset(-24, 4),
              child: _cloudCircle(20, color, opacity * 0.8),
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
