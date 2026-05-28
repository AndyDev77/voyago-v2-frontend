import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

final profileProvider =
    FutureProvider.family<UserProfile, String>((ref, userId) async {
  if (userId.isEmpty) {
    throw Exception('User ID required');
  }
  return ApiService.instance.getProfile(userId);
});
