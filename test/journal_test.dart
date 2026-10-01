import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:voyagooo/models/journal.dart';
import 'package:voyagooo/models/trip.dart';
import 'package:voyagooo/providers/auth_provider.dart';
import 'package:voyagooo/providers/journal_provider.dart';
import 'package:voyagooo/screens/journal_detail_screen.dart';
import 'package:voyagooo/screens/journal_screen.dart';
import 'package:voyagooo/widgets/journal/journal_story_studio.dart';

Trip _trip({String? start, String? end, int days = 2, DateTime? completedAt}) => Trip(
      id: 't',
      userId: 'u',
      destination: 'Lisbonne, Portugal',
      pace: 'equilibre',
      budget: 'moyen',
      durationDays: days,
      transports: const ['marche'],
      interests: const ['culture'],
      pois: const [],
      weather: const [],
      startDate: start,
      endDate: end,
      isPublic: true,
      likes: 0,
      createdAt: DateTime(2026, 1, 1),
      completedAt: completedAt,
    );

String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final _detailJson = {
  'trip_id': 'trip-1',
  'destination': 'Lisbonne, Portugal',
  'country': 'Portugal',
  'cover_image_url': null,
  'start_date': '2026-09-01',
  'end_date': '2026-09-02',
  'duration_days': 2,
  'completed_at': '2026-09-03T10:00:00Z',
  'journal_shared': false,
  'badge': {'title': 'Collectionneur de Coups de cœur', 'icon': 'favorite'},
  'stats': {
    'distance_km': 12.4,
    'places_count': 8,
    'visited_count': 5,
    'reviews_count': 4,
    'favorites_count': 3,
    'avg_rating_given': 4.5,
    'hidden_gems': 2,
    'photos_count': 6,
    'notes_count': 3,
    'xp_earned': 16,
  },
  'days': [
    {
      'day': 1,
      'date': '2026-09-01',
      'weather': {'date': '2026-09-01', 'weather_code': 1, 'temp_max': 27, 'temp_min': 19, 'icon': '⛅', 'summary': 'Nuageux'},
      'pois': [
        {
          'name': 'Mosteiro dos Jerónimos, chef-d\'œuvre manuélin au bord du Tage',
          'description': 'Monastère manuélin classé à l\'UNESCO.',
          'category': 'culture',
          'lat': 38.6979,
          'lng': -9.2068,
          'day': 1,
          'order': 1,
          'duration_minutes': 90,
          'visited': true,
          'entry': {
            'poi_name': 'Mosteiro dos Jerónimos',
            'day': 1,
            'note': 'Le cloître baigné de lumière dorée, un silence absolu avant l\'arrivée des groupes.',
            'mood_tags': ['Émerveillé', 'Serein', 'ArchitectureManuéline'],
            'photos': [],
            'visited': true,
          },
          'review': {'rating': 5, 'liked': true, 'comment': ''},
        },
        {
          'name': 'Pastéis de Belém',
          'description': 'La pâtisserie historique des pastéis de nata.',
          'category': 'gastronomie',
          'lat': 38.6975,
          'lng': -9.2032,
          'day': 1,
          'order': 2,
          'duration_minutes': 45,
          'hidden_gem': true,
          'visited': false,
          'entry': null,
          'review': null,
        },
      ],
    },
    {'day': 2, 'date': '2026-09-02', 'weather': null, 'pois': []},
  ],
};

Widget _app(Widget child, {List<Override> overrides = const []}) => ProviderScope(
      overrides: [isAuthenticatedProvider.overrideWith((ref) => true), ...overrides],
      child: MaterialApp(home: child),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340); // 360 x 780 dp
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr', null);
  });

  group('Trip.isPast (même règle que le serveur)', () {
    final today = DateTime.now();
    test('dernier jour passé → journal', () {
      expect(_trip(start: _ymd(today.subtract(const Duration(days: 10))), days: 3).isPast, isTrue);
    });
    test('voyage en cours ou à venir → carte', () {
      expect(_trip(start: _ymd(today), days: 3).isPast, isFalse);
      expect(_trip(start: _ymd(today.subtract(const Duration(days: 2))), days: 3).isPast, isFalse);
    });
    test('non daté → carte, sauf terminé manuellement', () {
      expect(_trip().isPast, isFalse);
      expect(_trip(completedAt: DateTime.now()).isPast, isTrue);
    });
    test('activeTrips retire les voyages passés', () {
      final trips = [_trip(), _trip(completedAt: DateTime.now())];
      expect(activeTrips(trips).length, 1);
    });
  });

  testWidgets('liste du journal : récapitulatif et carte de voyage', (tester) async {
    _phone(tester);
    final summary = JournalTripSummary.fromJson({..._detailJson, 'end_date': '2026-09-02'});
    await tester.pumpWidget(_app(
      const JournalScreen(),
      overrides: [journalListProvider.overrideWith((ref) async => [summary])],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Journal de voyage'), findsOneWidget);
    expect(find.text('lieux visités'), findsOneWidget);
    expect(find.text('Lisbonne'), findsOneWidget);
    expect(find.text('5/8 lieux'), findsOneWidget);
    expect(find.text('Collectionneur de Coups de cœur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('journal vide : invitation à planifier', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(
      const JournalScreen(),
      overrides: [journalListProvider.overrideWith((ref) async => <JournalTripSummary>[])],
    ));
    await tester.pumpAndSettle();
    expect(find.text('Ton journal t\'attend'), findsOneWidget);
    expect(find.text('Planifier un voyage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('détail : en-tête, métriques, jour, souvenir, pépite, filtres', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(
      const JournalDetailScreen(tripId: 'trip-1'),
      overrides: [journalDetailProvider('trip-1').overrideWith((ref) async => JournalDetail.fromJson(_detailJson))],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Lisbonne — 2 jours d\'exploration'), findsOneWidget);
    expect(find.text('BADGE DÉBLOQUÉ'), findsOneWidget);
    expect(find.text('12 km'), findsOneWidget);
    expect(find.text('5/8'), findsOneWidget);
    expect(find.text('+16 XP'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Tous les jours (2)'), 200, scrollable: scrollable);
    expect(find.text('Tous les jours (2)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Jour 1 • Culture'), 200, scrollable: scrollable);
    expect(find.textContaining('27°C'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('silence absolu'), 200, scrollable: scrollable);
    expect(find.text('#Émerveillé'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('PÉPITE'), 200, scrollable: scrollable);
    expect(find.text('Noter'), findsOneWidget);

    // Filtre « Jour 2 » : le jour 1 disparaît
    await tester.scrollUntilVisible(find.text('Tous les jours (2)'), -200, scrollable: scrollable);
    final chips = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right);
    await tester.scrollUntilVisible(find.text('Jour 2'), 120, scrollable: chips);
    await tester.tap(find.text('Jour 2'));
    await tester.pumpAndSettle();
    expect(find.text('Jour 1 • Culture'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('story 9:16 : rendu sans débordement', (tester) async {
    _phone(tester);
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 270,
          child: AspectRatio(aspectRatio: 9 / 16, child: JournalStoryCard(journal: JournalDetail.fromJson(_detailJson))),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Lisbonne'), findsOneWidget);
    expect(find.text('2 pépites'), findsOneWidget);
    expect(find.textContaining('Badge débloqué'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
