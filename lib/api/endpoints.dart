import 'dart:io';
import 'package:flutter/foundation.dart';

class Endpoints {
  Endpoints._();

  // Configuration dynamique de l'hôte Backend
  static const String _envBackendUrl = String.fromEnvironment('BACKEND_URL');

  // Hôtes Backend (Port NestJS : 3333)
  static const String localNetworkBackendUrl = 'http://10.75.1.14:3333';
  static const String androidEmulatorBackendUrl = 'http://10.0.2.2:3333';
  static const String localhostBackendUrl = 'http://localhost:3333';

  // Passer à true si test en Wi-Fi direct sans câble USB (sans adb reverse)
  static const bool useLanIpForDevice = false;

  static String get baseUrl {
    if (_envBackendUrl.isNotEmpty) {
      return _envBackendUrl;
    }
    if (kIsWeb) {
      return localhostBackendUrl;
    }
    if (Platform.isAndroid) {
      if (useLanIpForDevice) {
        return localNetworkBackendUrl;
      }
      // Par défaut avec câble USB + `adb reverse tcp:3333 tcp:3333`
      return localhostBackendUrl;
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

  // --- TRIPS MODULE ---
  static const String generateTrip = '/api/trips/generate';
  static String userTrips(String userId) => '/api/trips/$userId';
  static String tripDetail(String tripId) => '/api/trip/$tripId';

  // --- COMMUNITY MODULE ---
  static const String publicFeed = '/api/community/feed';
  static String likeTrip(String tripId) => '/api/community/trip/$tripId/like';

  // --- GAMIFICATION MODULE ---
  static String profile(String userId) => '/api/profile/$userId';
  static const String awardXp = '/api/profile/award-xp';
  static const String xpRewards = '/api/xp-rewards';
  static const String badges = '/api/badges';

  // --- PRO & PAYMENTS MODULE ---
  static const String proCheckout = '/api/pro/checkout';
  static String proStatus(String userId) => '/api/pro/status/$userId';

  // --- INTERESTS MODULE ---
  static const String interests = '/api/interests';
}
