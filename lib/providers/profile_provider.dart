import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';
import '../models/user_profile.dart';

final gamificationApiProvider = Provider<GamificationApi>((ref) => GamificationApi());

/// Provider pour le profil gamifié de l'utilisateur (XP, niveau, badges)
final profileProvider = FutureProvider.family<UserProfile, String>((ref, userId) async {
  if (userId.isEmpty) {
    throw ApiException(message: 'Identifiant utilisateur requis');
  }
  final api = ref.watch(gamificationApiProvider);
  return api.getProfile(userId);
});

/// Provider pour le catalogue des récompenses XP
final xpRewardsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(gamificationApiProvider);
  return api.getXpRewards();
});

/// Provider pour le catalogue des badges
final badgesCatalogProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(gamificationApiProvider);
  return api.getBadges();
});
