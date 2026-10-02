import 'dart:io';
import 'package:flutter/foundation.dart';

/// Environnements backend disponibles.
enum AppEnvironment {
  local('Local'),
  production('Production');

  const AppEnvironment(this.label);
  final String label;
}

/// Détermine l'environnement courant et l'URL du backend associée.
///
/// Ordre de priorité :
/// 1. `--dart-define=APP_ENV=local|prod` (choix explicite)
/// 2. Mode de compilation : release → production, debug/profile → local
///
/// `--dart-define=BACKEND_URL=...` remplace l'URL sans changer l'environnement.
class AppConfig {
  AppConfig._();

  static const String _envName = String.fromEnvironment('APP_ENV');
  static const String _backendUrlOverride = String.fromEnvironment('BACKEND_URL');

  // Backend de production
  static const String productionBackendUrl = 'https://api.voyagooo.com';

  // Hôtes Backend local (Port NestJS : 3333)
  // static const String localNetworkBackendUrl = 'http://192.168.1.81:3333';
  static const String localNetworkBackendUrl = 'http://10.75.1.6:3333'; // Autre réseau
  static const String androidEmulatorBackendUrl = 'http://10.0.2.2:3333';
  static const String localhostBackendUrl = 'http://localhost:3333';

  static final AppEnvironment environment = _resolveEnvironment();

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isLocal => environment == AppEnvironment.local;

  static AppEnvironment _resolveEnvironment() {
    switch (_envName.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.production;
      case 'local':
      case 'dev':
      case 'development':
        return AppEnvironment.local;
      case '':
        break;
      default:
        debugPrint('⚠️ APP_ENV inconnu "$_envName" : environnement choisi selon le mode de compilation.');
    }
    return kReleaseMode ? AppEnvironment.production : AppEnvironment.local;
  }

  static String get backendUrl {
    if (_backendUrlOverride.isNotEmpty) {
      return _backendUrlOverride;
    }
    if (isProduction) {
      return productionBackendUrl;
    }
    if (kIsWeb) {
      return localhostBackendUrl;
    }
    if (Platform.isAndroid) {
      // L'IP LAN est directement accessible par le téléphone (en Wi-Fi ou USB)
      // sans dépendre d'une règle adb reverse qui s'efface aux reconnexions
      return localNetworkBackendUrl;
    }
    return localhostBackendUrl;
  }
}
