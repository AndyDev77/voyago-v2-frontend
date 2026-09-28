import '../models/trip.dart';
import 'dio_client.dart';
import 'endpoints.dart';

class CommunityTripItem {
  final Trip trip;
  final String authorName;
  final String? authorPseudo;
  final String? authorAvatarEmoji;
  final String? authorPicture;
  final bool authorIsPro;

  CommunityTripItem({
    required this.trip,
    required this.authorName,
    this.authorPseudo,
    this.authorAvatarEmoji,
    this.authorPicture,
    this.authorIsPro = false,
  });

  factory CommunityTripItem.fromJson(Map<String, dynamic> json) {
    final tripMap = json['trip'] as Map<String, dynamic>? ?? json;
    final userMap = json['user'] as Map<String, dynamic>? ?? {};

    return CommunityTripItem(
      trip: Trip.fromJson(tripMap),
      authorName: userMap['name']?.toString() ?? 'Voyageur',
      authorPseudo: userMap['pseudo']?.toString(),
      authorAvatarEmoji: userMap['avatar_emoji']?.toString() ?? userMap['avatarEmoji']?.toString(),
      authorPicture: userMap['picture']?.toString(),
      authorIsPro: userMap['is_pro'] as bool? ?? userMap['isPro'] as bool? ?? false,
    );
  }

  String get authorDisplay => authorPseudo ?? authorName;
}

class CommunityApi {
  final DioClient _client;

  CommunityApi({DioClient? client}) : _client = client ?? DioClient.instance;

  /// Récupération du flux public des itinéraires partagés
  Future<List<CommunityTripItem>> getPublicFeed() async {
    final data = await _client.get(Endpoints.publicFeed);
    if (data is List) {
      return data
          .map((e) => CommunityTripItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Liker ou retirer un like sur un voyage
  Future<Map<String, dynamic>> likeTrip(String tripId) async {
    final data = await _client.post(Endpoints.likeTrip(tripId));
    return data as Map<String, dynamic>;
  }
}
