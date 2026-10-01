import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/day_weather.dart';

/// Particules météo animées au-dessus de la carte (pluie, averses, neige, brouillard, éclairs d'orage).
/// 100% IgnorePointer : zéro impact sur les interactions tactiles avec la carte Leaflet.
class MapWeatherEffectsLayer extends StatefulWidget {
  const MapWeatherEffectsLayer({
    super.key,
    required this.weather,
    this.topInset = 0,
  });

  final DayWeather weather;
  final double topInset;

  @override
  State<MapWeatherEffectsLayer> createState() => _MapWeatherEffectsLayerState();
}

class _MapWeatherEffectsLayerState extends State<MapWeatherEffectsLayer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  List<_ParticleSeed>? _seeds;

  void _ensureInitialized() {
    _seeds ??= _buildSeeds(widget.weather);
    _controller ??= AnimationController(
      vsync: this,
      duration: _durationFor(widget.weather),
    )..repeat();
  }

  @override
  void initState() {
    super.initState();
    _ensureInitialized();
  }

  @override
  void reassemble() {
    super.reassemble();
    _ensureInitialized();
  }

  @override
  void didUpdateWidget(covariant MapWeatherEffectsLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureInitialized();
    if (oldWidget.weather.weatherCode != widget.weather.weatherCode) {
      _seeds!
        ..clear()
        ..addAll(_buildSeeds(widget.weather));
      _controller!
        ..duration = _durationFor(widget.weather)
        ..repeat();
    }
  }

  Duration _durationFor(DayWeather w) {
    if (w.isSnowy) return const Duration(milliseconds: 4000);
    if (w.weatherCode >= 51 && w.weatherCode <= 57) {
      return const Duration(milliseconds: 1800); // Bruine
    }
    if (w.isRainy || w.isThunderstorm) {
      return const Duration(milliseconds: 1300); // Pluie soutenue
    }
    return const Duration(milliseconds: 2000);
  }

  List<_ParticleSeed> _buildSeeds(DayWeather w) {
    int count = 0;
    if (w.weatherCode >= 51 && w.weatherCode <= 57) {
      count = 55; // Bruine
    } else if (w.isRainy) {
      count = 95; // Pluie
    } else if (w.isThunderstorm) {
      count = 120; // Orage violent
    } else if (w.isSnowy) {
      count = 75; // Neige
    }

    final random = math.Random(w.weatherCode * 997 + 13);
    return List.generate(
      count,
      (_) => _ParticleSeed(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.55 + random.nextDouble() * 0.9,
        size: 0.6 + random.nextDouble(),
        drift: (random.nextDouble() - 0.5) * 0.08,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    final weather = widget.weather;

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Voile de brume / brouillard
            if (weather.isFoggy)
              _FogMistLayer(
                topInset: widget.topInset,
                progress: _controller!.value,
              ),

            // Précipitations (Pluie, Bruine, Neige)
            if (weather.hasPrecipitation)
              CustomPaint(
                painter: _PrecipitationPainter(
                  weather: weather,
                  progress: _controller!.value,
                  seeds: _seeds!,
                  topInset: widget.topInset,
                ),
              ),

            // Éclairs réalistes lors des orages
            if (weather.isThunderstorm)
              _ThunderFlashLayer(progress: _controller!.value),
          ],
        );
      },
    );
  }
}

class _FogMistLayer extends StatelessWidget {
  const _FogMistLayer({required this.topInset, required this.progress});

  final double topInset;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final drift = math.sin(progress * math.pi * 2) * 0.05;
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1 + drift, -1),
            end: Alignment(1 - drift, 1),
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThunderFlashLayer extends StatelessWidget {
  const _ThunderFlashLayer({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    // Éclair bref à 94% du cycle de l'animation
    final flash = progress > 0.93 && progress < 0.965;
    if (!flash) return const SizedBox.shrink();
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.white.withValues(alpha: 0.22),
      ),
    );
  }
}

class _ParticleSeed {
  const _ParticleSeed({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.drift,
  });

  final double x;
  final double y;
  final double speed;
  final double size;
  final double drift;
}

class _PrecipitationPainter extends CustomPainter {
  _PrecipitationPainter({
    required this.weather,
    required this.progress,
    required this.seeds,
    required this.topInset,
  });

  final DayWeather weather;
  final double progress;
  final List<_ParticleSeed> seeds;
  final double topInset;

  @override
  void paint(Canvas canvas, Size size) {
    final isSnow = weather.isSnowy;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = isSnow ? PaintingStyle.fill : PaintingStyle.stroke;

    for (final seed in seeds) {
      final y = ((seed.y + progress * seed.speed) % 1.0) * size.height;
      final x = (seed.x + progress * seed.drift) * size.width;

      if (isSnow) {
        paint.color = Colors.white.withValues(alpha: 0.6 + seed.size * 0.2);
        canvas.drawCircle(
          Offset(x, y),
          1.2 + seed.size,
          paint,
        );
      } else {
        final heavy = weather.isRainy || weather.isThunderstorm;
        paint
          ..color = Colors.white.withValues(
            alpha: heavy ? 0.38 + seed.size * 0.16 : 0.24 + seed.size * 0.1,
          )
          ..strokeWidth = heavy ? 1.4 + seed.size * 0.3 : 0.9 + seed.size * 0.2;
        final length = heavy ? 15.0 + seed.size * 6 : 9.0 + seed.size * 4;
        canvas.drawLine(
          Offset(x, y),
          Offset(x - 2.8, y + length),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PrecipitationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.weather.weatherCode != weather.weatherCode ||
        oldDelegate.topInset != topInset;
  }
}
