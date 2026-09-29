import 'package:flutter/material.dart';
import '../models/day_weather.dart';
import '../models/auth_user.dart';
import '../theme.dart';

/// Composant météo compact et transparent (sans fond de couleur opaque)
/// pour garantir une visibilité totale de la carte en dessous.
class WeatherOverlay extends StatelessWidget {
  final DayWeather weather;
  final String? aiTip;
  final int dayNumber;
  final String? ambianceLabel;
  final IconData? ambianceIcon;
  final VoidCallback? onTap;

  const WeatherOverlay({
    super.key,
    required this.weather,
    this.aiTip,
    this.dayNumber = 1,
    this.ambianceLabel,
    this.ambianceIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Left: Weather icon + Temperature
          Text(
            weather.icon,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 8),
          Text(
            '${weather.tempMax.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Condition & Day
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weather.summary,
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
                  if (ambianceIcon != null) ...[
                    Icon(
                      ambianceIcon,
                      size: 11,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    ambianceLabel != null
                        ? '$ambianceLabel · J$dayNumber'
                        : '↓ ${weather.tempMin.round()}° · J$dayNumber',
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

          const Spacer(),

          // Right: AI Tip Capsule
          if (aiTip != null && aiTip!.isNotEmpty)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: VoyagoColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: VoyagoColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: VoyagoColors.primary,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        aiTip!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  if (code >= 80) return "Fortes averses, imperméable et parapluie requis.";
  if (code >= 61) return "Pluie continue, prévoyez un bon imperméable.";
  if (code >= 71) {
    return sens == ThermalSensitivity.cold
        ? "Chutes de neige ! Doudoune épaisse, gants et bonnet indispensables."
        : "Chutes de neige ! Habillez-vous chaudement.";
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
