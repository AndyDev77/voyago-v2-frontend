import '../models/user_profile.dart';
import 'dio_client.dart';
import 'endpoints.dart';

class GamificationApi {
  final DioClient _client;

  GamificationApi({DioClient? client}) : _client = client ?? DioClient.instance;

  /// Récupération du profil gamifié (XP, niveau, badges, streak)
  Future<UserProfile> getProfile(String userId) async {
    final data = await _client.get(Endpoints.profile(userId));
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  /// Attribution d'XP pour une action (ex: generate_trip, first_swipe, share_trip)
  Future<Map<String, dynamic>> awardXp({
    required String userId,
    required String action,
  }) async {
    final payload = {
      'user_id': userId,
      'action': action,
    };
    final data = await _client.post(Endpoints.awardXp, data: payload);
    return data as Map<String, dynamic>;
  }

  /// Catalogue des récompenses XP & seuils de niveaux
  Future<Map<String, dynamic>> getXpRewards([String? userId]) async {
    final path = (userId != null && userId.isNotEmpty)
        ? '${Endpoints.xpRewards}/$userId'
        : Endpoints.xpRewards;
    final data = await _client.get(path);
    return data as Map<String, dynamic>;
  }

  /// Catalogue des badges disponibles
  Future<List<Map<String, dynamic>>> getBadges() async {
    final data = await _client.get(Endpoints.badges);
    if (data is List) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }
}
