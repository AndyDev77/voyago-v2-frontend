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
  final String? cityName;
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
    this.cityName,
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
                if (widget.cityName != null && widget.cityName!.isNotEmpty) ...[
                  Text(
                    widget.cityName!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
                ],
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
                        if (widget.cityName != null && widget.cityName!.isNotEmpty) ...[
                          const Icon(Icons.location_on, size: 11, color: VoyagoColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            widget.cityName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 2.5,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
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

/// Conseils météo IA personnalisés adaptés à la météo exacte et à la sensibilité thermique
String getWeatherAiTip(DayWeather weather, [ThermalSensitivity? sensitivity]) {
  final code = weather.weatherCode;
  final sens = sensitivity ?? ThermalSensitivity.balanced;
  final temp = weather.tempMax.round();

  // 1. Phénomènes météo majeurs (Pluie, Neige, Orage)
  if (code >= 95) {
    return "⚡ Alerte Orage : Privilégiez les activités abritées (musées, halles). Évitez les hauteurs et espaces découverts.";
  }
  if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
    return sens == ThermalSensitivity.cold
        ? "❄️ Chutes de neige ($temp°C) : Doudoune épaisse, écharpe, gants et chaussures étanches avec semelles antidérapantes."
        : "❄️ Chutes de neige ($temp°C) : Veste chaude imperméable, bonnet et chaussures adaptées pour marcher au sec.";
  }
  if (code >= 80 && code <= 82) {
    return "🌧️ Averses soutenues ($temp°C) : Manteau imperméable à capuche et parapluie indispensable. Privilégiez les étapes intérieures.";
  }
  if (code >= 61 && code <= 67) {
    if (sens == ThermalSensitivity.cold) {
      return "🌧️ Pluie & fraîcheur ($temp°C) : Manteau déperlant chaud, parapluie et pauses gourmandes régulières au chaud.";
    } else if (sens == ThermalSensitivity.warm) {
      return "🌧️ Pluie ($temp°C) : Coupe-vent imperméable léger et respirant + parapluie. Chaussures fermées recommandées.";
    }
    return "🌧️ Pluie continue ($temp°C) : Imperméable et parapluie indispensables pour explorer la ville confortablement.";
  }
  if (code >= 51 && code <= 57) {
    return "🌦️ Bruine passagère ($temp°C) : Veste déperlante ou coupe-vent léger amplement suffisant.";
  }
  if (code == 45 || code == 48) {
    return "🌫️ Bancs de brouillard ($temp°C) : Ambiance feutrée. Veste mi-saison et pause café chaleureuse recommandée.";
  }

  // 2. Températures et sensibilité thermique (Ciel dégagé ou nuageux)
  if (sens == ThermalSensitivity.cold) {
    if (weather.tempMin < 8 || temp < 12) {
      return "🧣 Frileux ($temp°C) : Air piquant ! Doudoune, écharpe douce et superposition de couches pour rester bien au chaud.";
    }
    if (temp < 18) {
      return "🧥 Frileux ($temp°C) : Fraîcheur modérée. Prévoyez un pull en maille et une veste coupe-vent pour les zones d'ombre.";
    }
    if (temp < 24) {
      return "🌤️ Frileux ($temp°C) : Climat doux. T-shirt avec gilet zippé facile à retirer au fil de la balade.";
    }
    return "☀️ Frileux ($temp°C) : Chaleur agréable. Vêtements légers en coton, petite veste fine pour la soirée.";
  }

  if (sens == ThermalSensitivity.warm) {
    if (temp > 28) {
      return "🔥 Chaleureux ($temp°C) : Forte chaleur ! Vêtements amples en lin, lunettes, casquette et hydratation fréquente.";
    }
    if (temp > 22) {
      return "😎 Chaleureux ($temp°C) : Chaleur idéale. Tenue ultra-légère, respirante et chaussures aérées.";
    }
    if (temp > 16) {
      return "🌿 Chaleureux ($temp°C) : Température parfaite pour marcher. Simple t-shirt ou chemise fluide.";
    }
    return "🍂 Chaleureux ($temp°C) : Fraîcheur vivifiante. Simple sweat ou veste fine suffit largement.";
  }

  // Sensibilité équilibrée
  if (temp > 30) {
    return "☀️ Forte chaleur ($temp°C) : Hydratation régulière, vêtements clairs en matières naturelles et crème solaire.";
  }
  if (temp > 23) {
    return "☀️ Beau temps ($temp°C) : Tenue estivale légère, lunettes de soleil et casquette pour profiter des terrasses et parcs.";
  }
  if (temp < 10) {
    return "🧥 Fraîcheur matinale ($temp°C) : Manteau chaud et tour de cou recommandés pour une découverte matinale agréable.";
  }
  if (code == 2 || code == 3) {
    return "☁️ Ciel couvert ($temp°C) : Climat doux et tempéré, idéal pour arpenter les rues et monuments sans souffrir du soleil.";
  }
  return "✨ Météo idéale ($temp°C) : Conditions optimales pour flâner, visiter les monuments et profiter pleinement de votre journée !";
}
