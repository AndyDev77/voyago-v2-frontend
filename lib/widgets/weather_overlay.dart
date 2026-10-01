import 'package:flutter/material.dart';
import '../models/day_weather.dart';
import '../models/auth_user.dart';
import '../theme.dart';

/// Composant météo compact et transparent pour garantir une visibilité totale de la carte.
/// Supporte un mode réduit (badge pillule discret) pour ne jamais masquer les POIs ou la carte,
/// et affiche les conseils IA sans coupure de texte.
class WeatherOverlay extends StatefulWidget {
  final DayWeather weather;
  final String? aiTip;
  final int dayNumber;
  final String? ambianceLabel;
  final IconData? ambianceIcon;
  final bool isMinimized;
  final VoidCallback? onToggleMinimize;
  final VoidCallback? onTap;

  const WeatherOverlay({
    super.key,
    required this.weather,
    this.aiTip,
    this.dayNumber = 1,
    this.ambianceLabel,
    this.ambianceIcon,
    this.isMinimized = false,
    this.onToggleMinimize,
    this.onTap,
  });

  @override
  State<WeatherOverlay> createState() => _WeatherOverlayState();
}

class _WeatherOverlayState extends State<WeatherOverlay> {
  bool _tipExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isMinimized) {
      return Center(
        child: GestureDetector(
          onTap: widget.onToggleMinimize,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.weather.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.weather.tempMax.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.weather.summary,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'J${widget.dayNumber}',
                  style: const TextStyle(
                    color: VoyagoColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ligne supérieure : icône météo, température, résumé et bouton de repli
          Row(
            children: [
              Text(
                widget.weather.icon,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.weather.tempMax.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.weather.summary,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 4),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.ambianceIcon != null) ...[
                          Icon(
                            widget.ambianceIcon,
                            size: 11,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          widget.ambianceLabel != null
                              ? '${widget.ambianceLabel} · J${widget.dayNumber}'
                              : '↓ ${widget.weather.tempMin.round()}° · J${widget.dayNumber}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bouton pour réduire la carte météo afin de dégager la vue sur la carte
              if (widget.onToggleMinimize != null)
                GestureDetector(
                  onTap: widget.onToggleMinimize,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),

          // Ligne inférieure : Conseil IA complet sans troncature
          if (widget.aiTip != null && widget.aiTip!.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _tipExpanded = !_tipExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: VoyagoColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: VoyagoColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.auto_awesome,
                        color: VoyagoColors.primary,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.aiTip!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                        maxLines: _tipExpanded ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Conseils météo IA personnalisés adaptés à la sensibilité thermique
String getWeatherAiTip(DayWeather weather, [ThermalSensitivity? sensitivity]) {
  final code = weather.weatherCode;
  final sens = sensitivity ?? ThermalSensitivity.balanced;

  // Conditions météorologiques fortes
  if (code >= 95) return "Orage prévu ! Privilégiez les activités abritées.";
  if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
    return sens == ThermalSensitivity.cold
        ? "Chutes de neige ! Doudoune épaisse, gants et bonnet indispensables."
        : "Chutes de neige ! Habillez-vous chaudement.";
  }
  if (code >= 80 && code <= 82) return "Averses soutenues, imperméable et parapluie requis.";
  if (code >= 61 && code <= 67) {
    if (sens == ThermalSensitivity.cold) {
      return "Temps pluvieux et frais : Manteau imperméable et parapluie indispensables.";
    } else if (sens == ThermalSensitivity.warm) {
      return "Pluie continue : Coupe-vent imperméable et respirant avec parapluie.";
    }
    return "Pluie continue, prévoyez un bon imperméable et un parapluie.";
  }
  if (code >= 51 && code <= 57) {
    return "Bruine passagère : Veste déperlante ou coupe-vent conseillé.";
  }


  // Conseils vestimentaires hyper-personnalisés selon sensibilité thermique
  if (sens == ThermalSensitivity.cold) {
    if (weather.tempMin < 10) return "Frileux : Matinée glaciale, doudoune et écharpe recommandées !";
    if (weather.tempMax < 20) return "Frileux : Prévoyez un pull chaud et une veste en superposition.";
    if (weather.tempMax < 25) return "Frileux : Température douce, emportez un gilet pour les passages à l'ombre.";
    return "Frileux : Belle journée chaude, t-shirt idéal avec petite veste pour le soir.";
  }

  if (sens == ThermalSensitivity.warm) {
    if (weather.tempMax > 28) return "Chaleureux : Forte chaleur ! Vêtements en lin très légers et hydratation.";
    if (weather.tempMax > 22) return "Chaleureux : Tenue ultra-légère et respirante conseillée.";
    if (weather.tempMin > 17) return "Chaleureux : Nuit douce, t-shirt léger amplement suffisant.";
    if (weather.tempMax < 16) return "Chaleureux : Fraîcheur modérée, un simple sweat ou veste légère suffit.";
    return "Chaleureux : Conditions idéales, tenue aérée et lunettes de soleil.";
  }

  // Sensibilité équilibrée
  if (weather.tempMax > 30) return "Forte chaleur ! Pensez à bien vous hydrater.";
  if (weather.tempMax > 24) return "Beau temps ensoleillé ! Crème solaire conseillée.";
  if (weather.tempMin < 8) return "Matinée fraîche, emportez une veste.";
  if (code >= 51) return "Bruine légère, un coupe-vent suffit.";
  if (code >= 45) return "Brouillard matinal. Idéal pour un café chaud.";
  if (code >= 2) return "Ciel nuageux, température agréable pour marcher.";
  return "Conditions idéales pour explorer la ville !";
}
