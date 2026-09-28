# 🦜 Voyago — Frontend Flutter

> Application mobile **Voyago** — planification de voyage gamifiée. Construite avec **Flutter + Riverpod + flutter_map**.

[![Flutter](https://img.shields.io/badge/Flutter-3-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/Riverpod-2-00BCD4)](https://riverpod.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-green)](https://flutter.dev/)

---

## 📋 Table des matières

1. [Concept](#-concept)
2. [Stack technique](#-stack-technique)
3. [Architecture](#-architecture)
4. [Écrans](#-écrans)
5. [Installation locale](#-installation-locale)
6. [Configuration](#-configuration)
7. [Lancer l'app](#-lancer-lapp)

---

## 💡 Concept

**Voyago** transforme la planification de voyage en jeu :
- 🃏 Swipe Tinder pour choisir tes envies
- 🤖 IA Claude génère un itinéraire personnalisé avec GPS, photos et météo
- 🏆 Gagne des XP, monte de niveau, débloque des badges
- 👥 Partage tes voyages avec la communauté
- 💎 Voyago Pro pour les voyageurs sérieux

---

## 🛠 Stack technique

| Technologie | Usage |
|---|---|
| **Flutter 3** | Framework UI cross-platform |
| **Riverpod 2** | Gestion d'état |
| **GoRouter** | Navigation déclarative |
| **Dio** | Client HTTP |
| **flutter_map** | Cartes OpenStreetMap (natif) |
| **SharedPreferences** | Stockage local (token, user_id) |
| **url_launcher** | Ouverture Stripe Checkout |
| **cached_network_image** | Images optimisées |
| **flutter_animate** | Animations fluides |

---

## 🏗 Architecture

```
lib/
├── main.dart           # Point d'entrée, initialisation
├── router.dart         # GoRouter — 11 routes
├── theme.dart          # ThemeData Voyago (dark, #58CC02)
├── models/             # Dart models avec fromJson/toJson
│   ├── auth_user.dart
│   ├── trip.dart
│   ├── poi.dart
│   ├── day_weather.dart
│   ├── interest.dart
│   └── user_profile.dart
├── services/
│   ├── api_service.dart     # Tous les appels API (Dio)
│   └── storage_service.dart # SharedPreferences wrapper
├── providers/               # Riverpod StateNotifier & FutureProvider
│   ├── auth_provider.dart
│   ├── trips_provider.dart
│   ├── interests_provider.dart
│   └── profile_provider.dart
├── screens/                 # 11 écrans
└── widgets/                 # 7 widgets réutilisables
```

---

## 📱 Écrans

| Écran | Route | Description |
|---|---|---|
| Home | `/` | Accueil, XP/niveau, navigation |
| Auth | `/auth` | Connexion / Inscription (email + Google) |
| Mot de passe oublié | `/forgot-password` | Reset 2 étapes |
| Swipe | `/swipe` | Sélection Tinder des intérêts |
| Configure | `/configure` | Paramètres du voyage |
| Itinéraire | `/itinerary/:tripId` | Carte + POIs + météo |
| Pricing | `/pricing` | Offres Voyago Pro |
| Profil | `/profile` | Profil, XP, badges, voyages |
| Communauté | `/community` | Feed public |
| Récompenses XP | `/xp-rewards` | Système de niveaux |
| Profil public | `/user/:id` | Voir le profil d'un autre |

---

## 🚀 Installation locale

### Prérequis
- Flutter SDK 3.x
- Android Studio (émulateur) ou Xcode (iOS)
- Backend Voyago lancé sur port 8001

### Étapes

```bash
# Cloner le repo
git clone https://github.com/AndyDev77/voyago-v2-frontend.git
cd voyago-v2-frontend

# Installer les dépendances
flutter pub get

# Lancer l'app
flutter run
```

---

## ⚙️ Configuration

Dans `lib/services/api_service.dart`, l'URL du backend s'adapte automatiquement selon la plateforme ou via `--dart-define` :

```dart
// IP locale actuelle de la machine : 192.168.1.81 (Port 8001)

// 1. Émulateur Android (redirection automatique)
const String androidEmulatorBackendUrl = 'http://10.0.2.2:8001';

// 2. Vrai téléphone / Appareil physique (Wi-Fi local)
const String localNetworkBackendUrl = 'http://192.168.1.81:8001';

// 3. Simulateur iOS / Web / Desktop
const String localhostBackendUrl = 'http://localhost:8001';
```

> **Astuce :** Vous pouvez aussi surcharger l'URL au lancement sans modifier le code :
> ```bash
> flutter run --dart-define=BACKEND_URL=http://192.168.1.81:8001
> ```

---

## ▶️ Lancer l'app

```bash
# Vérifier les appareils disponibles
flutter devices

# Lancer sur l'émulateur Android
flutter run

# Hot reload (pendant l'exécution)
# Appuie sur 'r' dans le terminal

# Hot restart
# Appuie sur 'R' dans le terminal

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## 🎨 Design System

| Élément | Valeur |
|---|---|
| Couleur primaire | `#58CC02` (Voyago Green) |
| Fond | `#0F1117` (dark) |
| Surface | `#1A1D27` |
| Texte | `#FFFFFF` |
| Mode | Dark uniquement |
| Border radius | 16px (standard), 24px (cards) |
| Mascotte | 🦜 |

---

## 🗺 Cartes

L'app utilise **flutter_map** avec les tuiles **OpenStreetMap** — aucune clé API requise.
Les marqueurs POI sont numérotés avec la couleur Voyago Green (`#58CC02`).

---

*Voyago — Voyage. Joue. Découvre. 🦜*
