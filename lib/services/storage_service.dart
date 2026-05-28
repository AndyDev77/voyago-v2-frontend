import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _sessionTokenKey = 'session_token';
  static const String _userIdKey = 'user_id';
  static const String _selectedInterestsKey = 'selected_interests';
  static const String _guestUserIdKey = 'guest_user_id';

  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) throw StateError('StorageService not initialized');
    return _prefs!;
  }

  // Session token
  String? get sessionToken => _p.getString(_sessionTokenKey);

  Future<void> setSessionToken(String token) async {
    await _p.setString(_sessionTokenKey, token);
  }

  Future<void> clearSessionToken() async {
    await _p.remove(_sessionTokenKey);
  }

  // User ID
  String? get userId => _p.getString(_userIdKey);

  Future<void> setUserId(String id) async {
    await _p.setString(_userIdKey, id);
  }

  Future<void> clearUserId() async {
    await _p.remove(_userIdKey);
  }

  // Guest user ID
  String? get guestUserId => _p.getString(_guestUserIdKey);

  Future<void> setGuestUserId(String id) async {
    await _p.setString(_guestUserIdKey, id);
  }

  // Selected interests
  List<String> get selectedInterests {
    return _p.getStringList(_selectedInterestsKey) ?? [];
  }

  Future<void> setSelectedInterests(List<String> ids) async {
    await _p.setStringList(_selectedInterestsKey, ids);
  }

  Future<void> clearSelectedInterests() async {
    await _p.remove(_selectedInterestsKey);
  }

  // Clear all auth data
  Future<void> clearAuth() async {
    await Future.wait([
      _p.remove(_sessionTokenKey),
      _p.remove(_userIdKey),
    ]);
  }

  // Clear everything
  Future<void> clearAll() async {
    await _p.clear();
  }
}
