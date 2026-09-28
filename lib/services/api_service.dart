import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'storage_service.dart';
import '../models/interest.dart';
import '../models/trip.dart';
import '../models/auth_user.dart';
import '../models/user_profile.dart';

// Configuration URL Backend :
// IP locale machine hôte actuelle : 192.168.1.81 (Port : 8001)
// - Émulateur Android standard : http://10.0.2.2:8001 (ou http://192.168.1.81:8001)
// - Appareil physique (Wi-Fi local) : http://192.168.1.81:8001
// - Web / Simulateur iOS / Desktop : http://localhost:8001 (ou http://192.168.1.81:8001)
// Surchargeable via --dart-define=BACKEND_URL=http://192.168.1.81:8001
const String _envBackendUrl = String.fromEnvironment('BACKEND_URL');

String get defaultBackendUrl {
  if (_envBackendUrl.isNotEmpty) {
    return _envBackendUrl;
  }
  if (kIsWeb) {
    return 'http://localhost:8001';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8001';
  }
  return 'http://localhost:8001';
}

// Raccourcis d'URL utiles
const String localNetworkBackendUrl = 'http://192.168.1.81:8001';
const String androidEmulatorBackendUrl = 'http://10.0.2.2:8001';
const String localhostBackendUrl = 'http://localhost:8001';
const String backendUrl = 'http://10.0.2.2:8001';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException({this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: defaultBackendUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = StorageService.instance.sessionToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  DioException? _wrap(dynamic e) {
    if (e is DioException) return e;
    return null;
  }

  ApiException _handleError(dynamic e) {
    final dioErr = _wrap(e);
    if (dioErr != null) {
      final statusCode = dioErr.response?.statusCode;
      final data = dioErr.response?.data;
      String message = 'Une erreur est survenue';
      if (data is Map) {
        message = data['detail']?.toString() ??
            data['message']?.toString() ??
            data['error']?.toString() ??
            message;
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }
      return ApiException(statusCode: statusCode, message: message);
    }
    return ApiException(message: e.toString());
  }

  // AUTH
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post('/api/auth/email/login', data: {
        'email': email,
        'password': password,
      });
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    String? pseudo,
    String? avatarEmoji,
    String? dateOfBirth,
    String? country,
  }) async {
    try {
      final resp = await _dio.post('/api/auth/email/signup', data: {
        'name': name,
        'email': email,
        'password': password,
        if (pseudo != null && pseudo.isNotEmpty) 'pseudo': pseudo,
        if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (country != null) 'country': country,
      });
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {
      // Ignore errors on logout
    }
  }

  Future<AuthUser> getMe() async {
    try {
      final resp = await _dio.get('/api/auth/me');
      return AuthUser.fromJson(resp.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthUser> updateProfile(Map<String, dynamic> data) async {
    try {
      final resp = await _dio.put('/api/auth/me', data: data);
      return AuthUser.fromJson(resp.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/api/auth/forgot-password', data: {'email': email});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/api/auth/reset-password', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAuthOptions() async {
    try {
      final resp = await _dio.get('/api/auth/options');
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> googleSession(String token) async {
    try {
      final resp = await _dio.post('/api/auth/google/session', data: {
        'token': token,
      });
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // INTERESTS
  Future<List<Interest>> getInterests() async {
    try {
      final resp = await _dio.get('/api/interests');
      final data = resp.data;
      if (data is List) {
        return data.map((e) => Interest.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is Map && data['interests'] is List) {
        return (data['interests'] as List)
            .map((e) => Interest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // TRIPS
  Future<Trip> generateTrip({
    required String destination,
    required int durationDays,
    required String pace,
    required String budget,
    required List<String> transports,
    required List<String> interests,
    String? userId,
  }) async {
    try {
      final resp = await _dio.post('/api/trips/generate', data: {
        'destination': destination,
        'duration_days': durationDays,
        'pace': pace,
        'budget': budget,
        'transports': transports,
        'interests': interests,
        if (userId != null) 'user_id': userId,
      });
      return Trip.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        throw ApiException(statusCode: 402, message: 'Pro required');
      }
      throw _handleError(e);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Trip>> getTrips(String userId) async {
    try {
      final resp = await _dio.get('/api/trips/$userId');
      final data = resp.data;
      if (data is List) {
        return data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is Map && data['trips'] is List) {
        return (data['trips'] as List)
            .map((e) => Trip.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Trip> getTrip(String tripId) async {
    try {
      final resp = await _dio.get('/api/trip/$tripId');
      return Trip.fromJson(resp.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PROFILE
  Future<UserProfile> getProfile(String userId) async {
    try {
      final resp = await _dio.get('/api/profile/$userId');
      return UserProfile.fromJson(resp.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPublicUser(String userId) async {
    try {
      final resp = await _dio.get('/api/community/user/$userId');
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> awardXp(String userId, String action) async {
    try {
      await _dio.post('/api/profile/xp', data: {
        'user_id': userId,
        'action': action,
      });
    } catch (_) {
      // Non-critical, ignore
    }
  }

  // COMMUNITY
  Future<List<Map<String, dynamic>>> getCommunityFeed() async {
    try {
      final resp = await _dio.get('/api/community/feed');
      final data = resp.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map && data['feed'] is List) {
        return (data['feed'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // BADGES
  Future<List<Map<String, dynamic>>> getBadges() async {
    try {
      final resp = await _dio.get('/api/badges');
      final data = resp.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['badges'] is List) {
        return (data['badges'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // XP REWARDS
  Future<Map<String, dynamic>> getXpRewards() async {
    try {
      final resp = await _dio.get('/api/xp/rewards');
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PRO
  Future<List<Map<String, dynamic>>> getProTiers() async {
    try {
      final resp = await _dio.get('/api/pro/tiers');
      final data = resp.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['tiers'] is List) {
        return (data['tiers'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createCheckout(String tierId) async {
    try {
      final resp = await _dio.post('/api/pro/checkout', data: {
        'tier_id': tierId,
      });
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProStatus(String sessionId) async {
    try {
      final resp = await _dio.get('/api/pro/status/$sessionId');
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProMe() async {
    try {
      final resp = await _dio.get('/api/pro/me');
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
