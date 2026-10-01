import 'package:flutter/material.dart';
import 'package:rate_my_app/rate_my_app.dart';

/// Demande de note de l'application sur le store (rate_my_app), proposée au bon
/// moment : après un avis réussi sur un lieu, jamais au lancement.
class AppRatingService {
  AppRatingService._();
  static final AppRatingService instance = AppRatingService._();

  final RateMyApp _rateMyApp = RateMyApp(
    preferencesPrefix: 'voyagoRateApp_',
    minDays: 2,
    minLaunches: 4,
    remindDays: 7,
    remindLaunches: 8,
    googlePlayIdentifier: 'com.voyago.voyago',
  );

  bool _initialized = false;

  /// À appeler une fois au démarrage : compte les lancements de l'app.
  Future<void> init() async {
    try {
      await _rateMyApp.init();
      _initialized = true;
    } catch (e) {
      debugPrint('RateMyApp init error: $e');
    }
  }

  /// Propose de noter l'app si les conditions sont réunies (jours, lancements, rappel).
  Future<void> maybeAskForStoreRating(BuildContext context) async {
    if (!_initialized || !_rateMyApp.shouldOpenDialog || !context.mounted) return;
    await _rateMyApp.showRateDialog(
      context,
      title: 'Tu aimes voyager avec Voyago ? 🦜',
      message: 'Tes avis aident déjà les autres voyageurs. '
          'Une note sur le store nous aide à faire grandir la communauté !',
      rateButton: 'NOTER VOYAGO',
      noButton: 'NON MERCI',
      laterButton: 'PLUS TARD',
    );
  }
}
