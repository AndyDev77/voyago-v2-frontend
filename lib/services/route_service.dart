import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Résultat d'un calcul d'itinéraire entre deux points.
class RouteResult {
  /// Distance en mètres.
  final double distanceMeters;

  /// Durée estimée en secondes.
  final double durationSeconds;

  /// Points du tracé de la route (polyline).
  final List<LatLng> geometry;

  /// Nom de la rue de départ (si disponible).
  final String? originStreet;

  /// Nom de la rue d'arrivée (si disponible).
  final String? destinationStreet;

  const RouteResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
    this.originStreet,
    this.destinationStreet,
  });

  /// Distance formatée (ex: "1.2 km" ou "450 m").
  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  /// Durée formatée (ex: "6 min" ou "1h12").
  String get durationLabel {
    final totalMin = (durationSeconds / 60).ceil();
    if (totalMin < 60) return '$totalMin min';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }
}

/// Service de calcul d'itinéraire utilisant OSRM (100% gratuit, pas de clé API).
/// Cache mémoire intégré pour éviter de re-solliciter l'API lors de micro-mouvements.
class RouteService {
  RouteService._();
  static final RouteService instance = RouteService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  /// Cache par clé "<originRounded>|<destRounded>|<profile>" -> RouteResult
  final Map<String, _CacheEntry> _cache = {};
  static const int _maxCacheSize = 60;
  static const Duration _cacheTtl = Duration(minutes: 10);

  /// Profils OSRM supportés.
  static const String walking = 'foot';
  static const String driving = 'car';
  static const String cycling = 'bike';

  /// Calcule l'itinéraire entre [origin] et [destination] via OSRM.
  /// Utilise le profil [profile] (foot, car, bike). Fallback Haversine si réseau indisponible.
  Future<RouteResult> getRoute(
    LatLng origin,
    LatLng destination, {
    String profile = 'foot',
  }) async {
    final key = _cacheKey(origin, destination, profile);
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.time) < _cacheTtl) {
      return cached.result;
    }

    try {
      // OSRM public demo server (walking profile)
      final osrmProfile = profile == 'foot'
          ? 'foot'
          : profile == 'bike'
              ? 'bike'
              : 'car';

      final url =
          'https://router.project-osrm.org/route/v1/$osrmProfile/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=false';

      final response = await _dio.get(url);
      final data = response.data;

      if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];
        final distance = (route['distance'] as num).toDouble();
        final duration = (route['duration'] as num).toDouble();

        // Parse GeoJSON geometry
        final coords = route['geometry']['coordinates'] as List;
        final points = coords.map<LatLng>((c) {
          final coord = c as List;
          return LatLng(
            (coord[1] as num).toDouble(),
            (coord[0] as num).toDouble(),
          );
        }).toList();

        // Extract street names from waypoints
        String? originStreet;
        String? destStreet;
        if (data['waypoints'] != null) {
          final waypoints = data['waypoints'] as List;
          if (waypoints.isNotEmpty) {
            originStreet = waypoints.first['name']?.toString();
            if (waypoints.length > 1) {
              destStreet = waypoints.last['name']?.toString();
            }
          }
        }

        final result = RouteResult(
          distanceMeters: distance,
          durationSeconds: duration,
          geometry: points,
          originStreet: originStreet,
          destinationStreet: destStreet,
        );

        _putCache(key, result);
        return result;
      }
    } catch (_) {
      // Réseau indisponible → fallback Haversine
    }

    // Fallback : calcul à vol d'oiseau Haversine (majoré x1.35 pour marche en ville)
    final straightDist = _haversineDistance(origin, destination);
    final walkDist = straightDist * 1.35;
    final walkDuration = walkDist / 1.2; // ~1.2 m/s vitesse de marche moyenne

    return RouteResult(
      distanceMeters: walkDist,
      durationSeconds: walkDuration,
      geometry: [origin, destination], // Ligne droite en fallback
    );
  }

  /// Calcule les distances depuis [userPosition] vers chaque POI de la liste.
  /// Retourne une Map {index POI → RouteResult}.
  /// Utilise `Future.wait` pour paralléliser les appels.
  Future<Map<int, RouteResult>> getDistancesToPois(
    LatLng userPosition,
    List<LatLng> poiPositions, {
    String profile = 'foot',
  }) async {
    final futures = <int, Future<RouteResult>>{};
    for (int i = 0; i < poiPositions.length; i++) {
      futures[i] = getRoute(userPosition, poiPositions[i], profile: profile);
    }

    final results = <int, RouteResult>{};
    final entries = futures.entries.toList();
    final routeResults = await Future.wait(entries.map((e) => e.value));
    for (int i = 0; i < entries.length; i++) {
      results[entries[i].key] = routeResults[i];
    }
    return results;
  }

  /// Distance Haversine en mètres entre deux points GPS.
  static double _haversineDistance(LatLng a, LatLng b) {
    const R = 6371000.0; // Rayon moyen de la Terre en mètres
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final h = sinDLat * sinDLat +
        math.cos(_toRad(a.latitude)) * math.cos(_toRad(b.latitude)) * sinDLon * sinDLon;
    return 2 * R * math.asin(math.sqrt(h));
  }

  /// Distance rapide à vol d'oiseau en mètres (utilisation publique).
  static double straightLineDistance(LatLng a, LatLng b) => _haversineDistance(a, b);

  static double _toRad(double deg) => deg * math.pi / 180;

  String _cacheKey(LatLng a, LatLng b, String profile) {
    // Arrondi à ~100m pour grouper les requêtes proches
    final aLat = (a.latitude * 1000).round();
    final aLng = (a.longitude * 1000).round();
    final bLat = (b.latitude * 1000).round();
    final bLng = (b.longitude * 1000).round();
    return '$aLat,$aLng|$bLat,$bLng|$profile';
  }

  void _putCache(String key, RouteResult result) {
    if (_cache.length >= _maxCacheSize) {
      // Supprimer les entrées les plus anciennes
      final sortedKeys = _cache.keys.toList()
        ..sort((a, b) => _cache[a]!.time.compareTo(_cache[b]!.time));
      for (int i = 0; i < _maxCacheSize ~/ 3; i++) {
        _cache.remove(sortedKeys[i]);
      }
    }
    _cache[key] = _CacheEntry(result: result, time: DateTime.now());
  }
}

class _CacheEntry {
  final RouteResult result;
  final DateTime time;
  const _CacheEntry({required this.result, required this.time});
}
