import 'dart:io';
import 'package:flutter/foundation.dart';

class Endpoints {
  Endpoints._();

  // Configuration dynamique de l'hôte Backend
  static const String _envBackendUrl = String.fromEnvironment('BACKEND_URL');

  // Hôtes Backend (Port NestJS : 3333)
  static const String localNetworkBackendUrl = 'http://192.168.1.81:3333';
  // static const String localNetworkBackendUrl = 'http://10.75.1.14:3333'; // Autre réseau
  static const String androidEmulatorBackendUrl = 'http://10.0.2.2:3333';
  static const String localhostBackendUrl = 'http://localhost:3333';

  // Utiliser l'IP LAN directe (testé et validé à 100% depuis le smartphone)
  static const bool useLanIpForDevice = true;

  static String get baseUrl {
    if (_envBackendUrl.isNotEmpty) {
      return _envBackendUrl;
    }
    if (kIsWeb) {
      return localhostBackendUrl;
    }
    if (Platform.isAndroid) {
      // 192.168.1.81:3333 est directement accessible par le téléphone (en Wi-Fi ou USB)
      // sans dépendre d'une règle adb reverse qui s'efface aux reconnexions
      return localNetworkBackendUrl;
    }
    return localhostBackendUrl;
  }

  // --- HEALTH & DOCS ---
  static const String health = '/api';
  static const String swagger = '/api/docs';

  // --- AUTH MODULE ---
  static const String signupEmail = '/api/auth/email/signup';
  static const String loginEmail = '/api/auth/email/login';
  static const String googleSession = '/api/auth/google/session';
  static const String guestLogin = '/api/auth/guest';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String authOptions = '/api/auth/options';
  static const String updateProfile = '/api/auth/me';

  // --- UPLOAD MODULE ---
  static const String uploadProfilePicture = '/api/upload/profile-picture';

  // --- TRIPS MODULE ---
  static const String generateTrip = '/api/trips/generate';
  static String userTrips(String userId) => '/api/trips/$userId';
  static String tripDetail(String tripId) => '/api/trip/$tripId';

  // --- COMMUNITY MODULE ---
  static const String publicFeed = '/api/community/feed';
  static String likeTrip(String tripId) => '/api/community/trip/$tripId/like';
  static const String communityCircles = '/api/community/circles';
  static String circleDetail(String circleId) => '/api/community/circles/$circleId';
  static String joinCircle(String circleId) => '/api/community/circles/$circleId/join';
  static String leaveCircle(String circleId) => '/api/community/circles/$circleId/leave';
  static String circlePosts(String circleId) => '/api/community/circles/$circleId/posts';
  static String shareTripToCircle(String circleId) => '/api/community/circles/$circleId/share-trip';
  static String likeCommunityPost(String postId) => '/api/community/posts/$postId/like';

  // --- GAMIFICATION MODULE ---
  static String profile(String userId) => '/api/profile/$userId';
  static const String awardXp = '/api/profile/award-xp';
  static const String xpRewards = '/api/xp-rewards';
  static const String badges = '/api/badges';

  // --- PRO & PAYMENTS MODULE ---
  static const String proCheckout = '/api/pro/checkout';
  static String proStatus(String sessionId) => '/api/pro/status/$sessionId';

  // --- INTERESTS MODULE ---
  static const String interests = '/api/interests';
}
