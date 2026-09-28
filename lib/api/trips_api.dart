import '../models/trip.dart';
import 'dio_client.dart';
import 'endpoints.dart';

class TripsApi {
  final DioClient _client;

  TripsApi({DioClient? client}) : _client = client ?? DioClient.instance;

  /// Génération d'un itinéraire de voyage complet par l'IA (Claude Sonnet / Gemini)
  Future<Trip> generateTrip({
    required String destination,
    required int durationDays,
    required String pace,
    required List<String> transports,
    required String budget,
    required List<String> interests,
    String? tenantId,
  }) async {
    final payload = {
      'destination': destination.trim(),
      'duration_days': durationDays,
      'pace': pace,
      'transports': transports,
      'budget': budget,
      'interests': interests,
      if (tenantId != null) 'tenant_id': tenantId,
    };

    final data = await _client.post(Endpoints.generateTrip, data: payload);
    return Trip.fromJson(data as Map<String, dynamic>);
  }

  /// Récupération des voyages d'un utilisateur
  Future<List<Trip>> getUserTrips(String userId) async {
    final data = await _client.get(Endpoints.userTrips(userId));
    if (data is List) {
      return data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Récupération du détail d'un voyage
  Future<Trip> getTripById(String tripId) async {
    final data = await _client.get(Endpoints.tripDetail(tripId));
    return Trip.fromJson(data as Map<String, dynamic>);
  }
}
