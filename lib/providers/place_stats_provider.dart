import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';
import '../models/place_stats.dart';
import '../models/poi.dart';
import 'auth_provider.dart';

/// Clé locale d'un lieu dans le cache (le serveur fait sa propre normalisation).
String placeCacheKey(String name, double lat, double lng) =>
    '$name|${lat.toStringAsFixed(4)}|${lng.toStringAsFixed(4)}';

/// Cache des étoiles communautaires par lieu, chargées par lot pour les lieux affichés.
class PlaceStatsNotifier extends StateNotifier<Map<String, PlaceStats>> {
  final PlacesApi _api;
  final Set<String> _inFlight = {};

  PlaceStatsNotifier(Ref ref, {PlacesApi? api})
      : _api = api ?? PlacesApi(),
        super(const {}) {
    // « ma note » dépend de l'utilisateur connecté : on repart de zéro à chaque changement
    ref.listen<bool>(isAuthenticatedProvider, (_, __) {
      _inFlight.clear();
      state = const {};
    });
  }

  /// Charge en un seul appel les étoiles des lieux pas encore connus.
  Future<void> ensure(List<POI> pois) async {
    final missing = pois
        .where((p) {
          final key = placeCacheKey(p.name, p.lat, p.lng);
          return !state.containsKey(key) && !_inFlight.contains(key);
        })
        .toList();
    if (missing.isEmpty) return;

    final keys = missing.map((p) => placeCacheKey(p.name, p.lat, p.lng)).toList();
    _inFlight.addAll(keys);
    try {
      final stats = await _api.stats(missing);
      if (!mounted) return;
      state = {
        ...state,
        for (int i = 0; i < keys.length && i < stats.length; i++) keys[i]: stats[i],
      };
    } catch (_) {
      // Hors ligne : les cartes gardent la note IA
    } finally {
      _inFlight.removeAll(keys);
    }
  }

  void put(String name, double lat, double lng, PlaceStats stats) {
    state = {...state, placeCacheKey(name, lat, lng): stats};
  }
}

final placeStatsProvider = StateNotifierProvider<PlaceStatsNotifier, Map<String, PlaceStats>>((ref) {
  return PlaceStatsNotifier(ref);
});

final placesApiProvider = Provider<PlacesApi>((ref) => PlacesApi());
