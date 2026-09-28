import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';

final communityApiProvider = Provider<CommunityApi>((ref) => CommunityApi());

/// Provider pour le flux public communautaire
final communityFeedProvider = FutureProvider<List<CommunityTripItem>>((ref) async {
  final api = ref.watch(communityApiProvider);
  return api.getPublicFeed();
});
