import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poi.dart';
import '../models/trip.dart';
import 'route_service.dart';

/// Détecte l'arrivée du voyageur sur un lieu de son itinéraire.
/// Une seule demande d'avis par lieu et par voyage, mémorisée entre les sessions.
class ArrivalDetector {
  ArrivalDetector._();
  static final ArrivalDetector instance = ArrivalDetector._();

  static const String _prefsKey = 'voyago_arrivals_prompted';

  /// Rayon d'arrivée autour du lieu.
  static const double arrivalRadiusMeters = 70;

  /// Au-delà, la position GPS est trop imprécise pour conclure à une arrivée.
  static const double maxAccuracyMeters = 60;

  Set<String>? _prompted;

  Future<Set<String>> _load() async {
    if (_prompted != null) return _prompted!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _prompted = (prefs.getStringList(_prefsKey) ?? const []).toSet();
    } catch (_) {
      _prompted = <String>{};
    }
    return _prompted!;
  }

  String _key(Trip trip, POI poi) => '${trip.id}|${poi.name}';

  /// Renvoie le lieu du voyage sur lequel le voyageur vient d'arriver, s'il n'a pas
  /// déjà été sollicité pour celui-ci. Le lieu du jour affiché est prioritaire.
  Future<POI?> detect({
    required Trip trip,
    required LatLng position,
    required double accuracyMeters,
    required int selectedDay,
  }) async {
    if (accuracyMeters > maxAccuracyMeters || trip.pois.isEmpty) return null;
    final prompted = await _load();

    POI? best;
    double bestDistance = double.infinity;
    for (final poi in trip.pois) {
      if (prompted.contains(_key(trip, poi))) continue;
      final d = RouteService.straightLineDistance(position, LatLng(poi.lat, poi.lng));
      if (d > arrivalRadiusMeters) continue;
      // Départage : jour affiché d'abord, puis le plus proche
      final score = d - (poi.day == selectedDay ? 1000 : 0);
      if (score < bestDistance) {
        bestDistance = score;
        best = poi;
      }
    }
    return best;
  }

  Future<void> markPrompted(Trip trip, POI poi) async {
    final prompted = await _load();
    if (!prompted.add(_key(trip, poi))) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // On ne garde que les 300 dernières arrivées
      final list = prompted.toList();
      await prefs.setStringList(_prefsKey, list.length > 300 ? list.sublist(list.length - 300) : list);
    } catch (_) {}
  }
}
