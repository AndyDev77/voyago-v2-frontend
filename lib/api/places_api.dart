import '../models/place_stats.dart';
import '../models/poi.dart';
import 'dio_client.dart';
import 'endpoints.dart';

class PlacesApi {
  final DioClient _client;

  PlacesApi({DioClient? client}) : _client = client ?? DioClient.instance;

  /// Étoiles agrégées des lieux, dans le même ordre que [pois]
  Future<List<PlaceStats>> stats(List<POI> pois) async {
    if (pois.isEmpty) return [];
    final data = await _client.post(Endpoints.placeStats, data: {
      'places': pois.map((p) => {'name': p.name, 'lat': p.lat, 'lng': p.lng}).toList(),
    });
    return ((data as Map<String, dynamic>)['stats'] as List? ?? [])
        .map((e) => PlaceStats.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Note, like et commentaire d'un lieu visité
  Future<({PlaceStats stats, bool isNew, int? xp})> review({
    required String placeName,
    required double lat,
    required double lng,
    required int rating,
    String? comment,
    bool? liked,
    String? destination,
    String? tripId,
  }) async {
    final data = await _client.post(Endpoints.placeReviews, data: {
      'place_name': placeName,
      'lat': lat,
      'lng': lng,
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (liked != null) 'liked': liked,
      if (destination != null && destination.isNotEmpty) 'destination': destination,
      if (tripId != null && tripId.isNotEmpty) 'trip_id': tripId,
    });
    final map = data as Map<String, dynamic>;
    final gamification = map['gamification'] as Map<String, dynamic>?;
    return (
      stats: PlaceStats.fromJson(map['stats'] as Map<String, dynamic>),
      isNew: map['is_new'] == true,
      xp: (gamification?['xp'] as num?)?.toInt(),
    );
  }

  /// Derniers avis laissés par les voyageurs sur un lieu
  Future<List<PlaceReview>> latestReviews({
    required String name,
    required double lat,
    required double lng,
    int limit = 5,
  }) async {
    final data = await _client.get(Endpoints.placeReviews, queryParameters: {
      'name': name,
      'lat': lat,
      'lng': lng,
      'limit': limit,
    });
    return ((data as Map<String, dynamic>)['reviews'] as List? ?? [])
        .map((e) => PlaceReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
