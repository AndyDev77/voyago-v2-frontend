import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthState {
  final AuthUser? user;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool sessionLoaded;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
    this.sessionLoaded = false,
  });

  bool get isLoggedIn => user != null && token != null;

  bool get isGuest => user == null && token == null;

  AuthState copyWith({
    AuthUser? user,
    String? token,
    bool? isLoading,
    String? error,
    bool? sessionLoaded,
    bool clearUser = false,
    bool clearToken = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      sessionLoaded: sessionLoaded ?? this.sessionLoaded,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final StorageService _storage;

  AuthNotifier(this._api, this._storage) : super(const AuthState());

  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = _storage.sessionToken;
      final userId = _storage.userId;

      if (token != null && userId != null) {
        try {
          final user = await _api.getMe();
          state = AuthState(
            user: user,
            token: token,
            sessionLoaded: true,
          );
          return;
        } catch (_) {
          // Token expired or invalid — clear it
          await _storage.clearAuth();
        }
      }

      // Ensure we have a guest ID
      if (_storage.guestUserId == null) {
        final guestId = const Uuid().v4();
        await _storage.setGuestUserId(guestId);
      }

      state = AuthState(sessionLoaded: true);
    } catch (e) {
      state = AuthState(
        sessionLoaded: true,
        error: e.toString(),
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.login(email: email, password: password);
      final token = result['token']?.toString() ??
          result['access_token']?.toString() ??
          '';
      final user = AuthUser.fromJson(
        result['user'] as Map<String, dynamic>? ?? result,
      );

      await _storage.setSessionToken(token);
      await _storage.setUserId(user.userId);

      state = AuthState(user: user, token: token, sessionLoaded: true);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    String? pseudo,
    String? avatarEmoji,
    String? dateOfBirth,
    String? country,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.signup(
        name: name,
        email: email,
        password: password,
        pseudo: pseudo,
        avatarEmoji: avatarEmoji,
        dateOfBirth: dateOfBirth,
        country: country,
      );

      final token = result['token']?.toString() ??
          result['access_token']?.toString() ??
          '';
      final user = AuthUser.fromJson(
        result['user'] as Map<String, dynamic>? ?? result,
      );

      await _storage.setSessionToken(token);
      await _storage.setUserId(user.userId);

      state = AuthState(user: user, token: token, sessionLoaded: true);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    await _storage.clearAuth();
    state = AuthState(sessionLoaded: true);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _api.updateProfile(data);
      state = state.copyWith(user: updated, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiService.instance, StorageService.instance);
});
