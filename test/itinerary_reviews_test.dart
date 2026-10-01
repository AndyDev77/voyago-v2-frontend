import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyago/models/place_stats.dart';
import 'package:voyago/models/poi.dart';
import 'package:voyago/providers/auth_provider.dart';
import 'package:voyago/providers/notifications_provider.dart';
import 'package:voyago/providers/place_stats_provider.dart';
import 'package:voyago/widgets/itinerary_bottom_sheet.dart';
import 'package:voyago/widgets/notification_bell.dart';

/// Étoiles injectées sans réseau.
class _FakePlaceStats extends PlaceStatsNotifier {
  _FakePlaceStats(super.ref, Map<String, PlaceStats> initial) {
    state = initial;
  }

  @override
  Future<void> ensure(List<POI> pois) async {}
}

class _FakeNotifications extends NotificationsNotifier {
  _FakeNotifications(super.ref) {
    state = const NotificationsState(unreadCount: 3, loadedOnce: true);
  }

  @override
  Future<void> refresh() async {}
}

const _louvre = POI(
  name: 'Musée du Louvre',
  description: 'Le plus grand musée d\'art et d\'antiquités du monde.',
  category: 'culture',
  imageQuery: 'Louvre',
  lat: 48.8606,
  lng: 2.3376,
  day: 1,
  order: 1,
  durationMinutes: 120,
  rating: 4.9,
  reviewsCount: 12400,
);

const _sainteChapelle = POI(
  name: 'Sainte-Chapelle',
  description: 'Joyau gothique aux vitraux éblouissants sur l\'île de la Cité.',
  category: 'culture',
  imageQuery: 'Sainte Chapelle',
  lat: 48.8554,
  lng: 2.3450,
  day: 1,
  order: 2,
  durationMinutes: 60,
);

const _montmartre = POI(
  name: 'Basilique du Sacré-Cœur',
  description: 'Panorama sur tout Paris depuis la butte Montmartre.',
  category: 'culture',
  imageQuery: 'Sacre Coeur',
  lat: 48.8867,
  lng: 2.3431,
  day: 1,
  order: 3,
  durationMinutes: 75,
);

Widget _harness() {
  return ProviderScope(
    overrides: [
      isAuthenticatedProvider.overrideWith((ref) => false),
      placeStatsProvider.overrideWith(
        (ref) => _FakePlaceStats(ref, {
          placeCacheKey(_louvre.name, _louvre.lat, _louvre.lng): const PlaceStats(
            placeKey: 'musee-du-louvre@48.86,2.34',
            ratingAvg: 4.5,
            reviewsCount: 2,
            likesCount: 1,
            myRating: 4,
          ),
        }),
      ),
      notificationsProvider.overrideWith((ref) => _FakeNotifications(ref)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            ItineraryBottomSheet(
              pois: const [_louvre, _sainteChapelle, _montmartre],
              selectedDay: 1,
              totalDays: 2,
              destination: 'Paris',
              onDayChanged: (_) {},
              onNavigateToPoi: (_) {},
              transports: const ['marche', 'transport'],
              tripId: 'trip-test',
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('timeline : étoiles voyageurs, trajets selon le transport, horaires, cloche', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // téléphone 360 x 780 dp
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness());
    await tester.pump();

    // Le sheet ouvert en grand pour voir toute la journée
    await tester.drag(find.text('Jour 1').first, const Offset(0, -500));
    await tester.pumpAndSettle();

    // Étoiles : avis voyageurs pour le Louvre, note IA pour les autres
    expect(find.textContaining('4.5 (2 avis)', findRichText: true), findsOneWidget);
    expect(find.textContaining('Toi : 4★', findRichText: true), findsOneWidget);
    expect(find.textContaining('4.7 (', findRichText: true), findsWidgets);

    // Cloche avec badge des non lues
    expect(find.byType(NotificationBell), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Horaires enchaînés : 09:00, puis 2h de visite + trajet à pied arrondi aux 5 min
    expect(find.text('09:00'), findsOneWidget);

    // Louvre → Sainte-Chapelle (~800 m) : à pied ; Sainte-Chapelle → Sacré-Cœur (~3,5 km) : transport
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.textContaining('min à pied'), 150, scrollable: scrollable);
    expect(find.textContaining('min à pied'), findsWidgets);
    expect(find.text('~15 min à pied'), findsNothing); // ancien texte fixe
    expect(find.text('11:15'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('min en transport'), 150, scrollable: scrollable);
    expect(find.textContaining('min en transport'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('toucher les étoiles ouvre la notation (invité → connexion)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness());
    await tester.pump();
    await tester.drag(find.text('Jour 1').first, const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('4.5 (2 avis)', findRichText: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Musée du Louvre'), findsWidgets);
    expect(find.text('Connecte-toi pour noter ce lieu et gagner de l\'XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
