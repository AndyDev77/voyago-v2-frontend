import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';
import '../models/app_notification.dart';
import 'auth_provider.dart';

class NotificationsState {
  final List<AppNotification> items;
  final int unreadCount;
  final bool isLoading;
  final bool loadedOnce;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.loadedOnce = false,
  });

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoading,
    bool? loadedOnce,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        loadedOnce: loadedOnce ?? this.loadedOnce,
      );
}

/// Notifications de la cloche : chargées à la connexion, puis compteur rafraîchi
/// périodiquement tant que l'utilisateur est connecté.
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsApi _api;
  Timer? _pollTimer;
  bool _loggedIn = false;

  static const Duration _pollInterval = Duration(seconds: 90);

  NotificationsNotifier(Ref ref, {NotificationsApi? api})
      : _api = api ?? NotificationsApi(),
        super(const NotificationsState()) {
    ref.listen<bool>(isAuthenticatedProvider, (_, loggedIn) => _onAuthChanged(loggedIn), fireImmediately: true);
  }

  void _onAuthChanged(bool loggedIn) {
    _loggedIn = loggedIn;
    _pollTimer?.cancel();
    if (!loggedIn) {
      state = const NotificationsState();
      return;
    }
    refresh();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshUnreadCount());
  }

  Future<void> refresh() async {
    if (!_loggedIn) return;
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.list();
      if (!mounted) return;
      state = NotificationsState(items: res.items, unreadCount: res.unreadCount, loadedOnce: true);
    } catch (_) {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _refreshUnreadCount() async {
    if (!_loggedIn) return;
    try {
      final count = await _api.unreadCount();
      if (!mounted) return;
      // Nouvelles notifications côté serveur : on recharge la liste
      if (count != state.unreadCount) {
        await refresh();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;
    final previous = state;
    state = state.copyWith(
      items: state.items.map((n) => n.read ? n : n.copyWith(read: true)).toList(),
      unreadCount: 0,
    );
    try {
      await _api.markAllRead();
    } catch (_) {
      if (mounted) state = previous;
    }
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.read) return;
    state = state.copyWith(
      items: state.items.map((n) => n.id == notification.id ? n.copyWith(read: true) : n).toList(),
      unreadCount: (state.unreadCount - 1).clamp(0, 1 << 30),
    );
    try {
      await _api.markRead(notification.id);
    } catch (_) {}
  }

  /// Arrivée sur un lieu : la notification apparaît aussitôt dans la cloche.
  Future<AppNotification?> recordArrival({
    required String placeName,
    required double lat,
    required double lng,
    String? tripId,
    String? destination,
    int? day,
    String? imageUrl,
  }) async {
    if (!_loggedIn) return null;
    try {
      final notification = await _api.recordArrival(
        placeName: placeName,
        lat: lat,
        lng: lng,
        tripId: tripId,
        destination: destination,
        day: day,
        imageUrl: imageUrl,
      );
      if (!mounted) return notification;
      final exists = state.items.any((n) => n.id == notification.id);
      if (!exists) {
        state = state.copyWith(
          items: [notification, ...state.items],
          unreadCount: state.unreadCount + (notification.read ? 0 : 1),
        );
      }
      return notification;
    } catch (_) {
      return null;
    }
  }

  /// Après un avis : la demande d'avis du lieu est traitée (comme côté serveur).
  void markPlaceReviewed(String placeName) {
    var resolved = 0;
    final items = state.items.map((n) {
      if (n.isArrival && n.placeName == placeName && !n.isReviewed) {
        if (!n.read) resolved++;
        return n.copyWith(read: true, data: {...n.data, 'reviewed': true});
      }
      return n;
    }).toList();
    state = state.copyWith(items: items, unreadCount: (state.unreadCount - resolved).clamp(0, 1 << 30));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});
