import 'dart:convert';
import 'package:http/http.dart' as http;

class DestinationItem {
  final String name;
  final String country;
  final String countryCode;
  final String flagEmoji;
  final String subtitle;
  final double lat;
  final double lng;
  final bool isPopular;

  const DestinationItem({
    required this.name,
    required this.country,
    required this.countryCode,
    required this.flagEmoji,
    required this.subtitle,
    required this.lat,
    required this.lng,
    this.isPopular = false,
  });

  String get fullTitle => country.isNotEmpty ? '$name, $country' : name;
}

class DestinationService {
  DestinationService._();
  static final DestinationService instance = DestinationService._();

  static String countryCodeToEmoji(String code) {
    if (code.length != 2) return '🌍';
    final upper = code.toUpperCase();
    final firstLetter = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  static const List<DestinationItem> popularDestinations = [
    DestinationItem(
      name: 'Tokyo',
      country: 'Japon',
      countryCode: 'JP',
      flagEmoji: '🇯🇵',
      subtitle: 'Kanto, Japon',
      lat: 35.6762,
      lng: 139.6503,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Paris',
      country: 'France',
      countryCode: 'FR',
      flagEmoji: '🇫🇷',
      subtitle: 'Île-de-France, France',
      lat: 48.8566,
      lng: 2.3522,
      isPopular: true,
    ),
    DestinationItem(
      name: 'New York',
      country: 'États-Unis',
      countryCode: 'US',
      flagEmoji: '🇺🇸',
      subtitle: 'New York, USA',
      lat: 40.7128,
      lng: -74.0060,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Rome',
      country: 'Italie',
      countryCode: 'IT',
      flagEmoji: '🇮🇹',
      subtitle: 'Latium, Italie',
      lat: 41.9028,
      lng: 12.4964,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Londres',
      country: 'Royaume-Uni',
      countryCode: 'GB',
      flagEmoji: '🇬🇧',
      subtitle: 'Angleterre, Royaume-Uni',
      lat: 51.5074,
      lng: -0.1278,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Marrakech',
      country: 'Maroc',
      countryCode: 'MA',
      flagEmoji: '🇲🇦',
      subtitle: 'Marrakech-Safi, Maroc',
      lat: 31.6295,
      lng: -7.9811,
      isPopular: true,
    ),
  ];

  static const List<DestinationItem> _allPresets = [
    ...popularDestinations,
    DestinationItem(
      name: 'Barcelone',
      country: 'Espagne',
      countryCode: 'ES',
      flagEmoji: '🇪🇸',
      subtitle: 'Catalogne, Espagne',
      lat: 41.3851,
      lng: 2.1734,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Dubai',
      country: 'Émirats Arabes Unis',
      countryCode: 'AE',
      flagEmoji: '🇦🇪',
      subtitle: 'Émirat de Dubaï, EAU',
      lat: 25.2048,
      lng: 55.2708,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Kyoto',
      country: 'Japon',
      countryCode: 'JP',
      flagEmoji: '🇯🇵',
      subtitle: 'Kansai, Japon',
      lat: 35.0116,
      lng: 135.7681,
    ),
    DestinationItem(
      name: 'Bangkok',
      country: 'Thaïlande',
      countryCode: 'TH',
      flagEmoji: '🇹🇭',
      subtitle: 'Bangkok, Thaïlande',
      lat: 13.7563,
      lng: 100.5018,
    ),
    DestinationItem(
      name: 'Amsterdam',
      country: 'Pays-Bas',
      countryCode: 'NL',
      flagEmoji: '🇳🇱',
      subtitle: 'Hollande-Septentrionale, Pays-Bas',
      lat: 52.3676,
      lng: 4.9041,
    ),
    DestinationItem(
      name: 'Berlin',
      country: 'Allemagne',
      countryCode: 'DE',
      flagEmoji: '🇩🇪',
      subtitle: 'Berlin, Allemagne',
      lat: 52.5200,
      lng: 13.4050,
    ),
    DestinationItem(
      name: 'Lisbonne',
      country: 'Portugal',
      countryCode: 'PT',
      flagEmoji: '🇵🇹',
      subtitle: 'District de Lisbonne, Portugal',
      lat: 38.7223,
      lng: -9.1393,
    ),
    DestinationItem(
      name: 'Sydney',
      country: 'Australie',
      countryCode: 'AU',
      flagEmoji: '🇦🇺',
      subtitle: 'Nouvelle-Galles du Sud, Australie',
      lat: -33.8688,
      lng: 151.2093,
    ),
    DestinationItem(
      name: 'Montréal',
      country: 'Canada',
      countryCode: 'CA',
      flagEmoji: '🇨🇦',
      subtitle: 'Québec, Canada',
      lat: 45.5017,
      lng: -73.5673,
    ),
    DestinationItem(
      name: 'Rio de Janeiro',
      country: 'Brésil',
      countryCode: 'BR',
      flagEmoji: '🇧🇷',
      subtitle: 'État de Rio, Brésil',
      lat: -22.9068,
      lng: -43.1729,
    ),
    DestinationItem(
      name: 'Abidjan',
      country: 'Côte d\'Ivoire',
      countryCode: 'CI',
      flagEmoji: '🇨🇮',
      subtitle: 'Lagunes, Côte d\'Ivoire',
      lat: 5.3600,
      lng: -4.0083,
    ),
    DestinationItem(
      name: 'Dakar',
      country: 'Sénégal',
      countryCode: 'SN',
      flagEmoji: '🇸🇳',
      subtitle: 'Cap-Vert, Sénégal',
      lat: 14.7167,
      lng: -17.4677,
    ),
    DestinationItem(
      name: 'Séoul',
      country: 'Corée du Sud',
      countryCode: 'KR',
      flagEmoji: '🇰🇷',
      subtitle: 'Sudogwon, Corée du Sud',
      lat: 37.5665,
      lng: 126.9780,
    ),
    DestinationItem(
      name: 'Singapour',
      country: 'Singapour',
      countryCode: 'SG',
      flagEmoji: '🇸🇬',
      subtitle: 'République de Singapour',
      lat: 1.3521,
      lng: 103.8198,
    ),
    DestinationItem(
      name: 'Athènes',
      country: 'Grèce',
      countryCode: 'GR',
      flagEmoji: '🇬🇷',
      subtitle: 'Attique, Grèce',
      lat: 37.9838,
      lng: 23.7275,
    ),
    DestinationItem(
      name: 'Prague',
      country: 'Tchéquie',
      countryCode: 'CZ',
      flagEmoji: '🇨🇿',
      subtitle: 'Bohême centrale, Tchéquie',
      lat: 50.0755,
      lng: 14.4378,
    ),
    DestinationItem(
      name: 'Vienne',
      country: 'Autriche',
      countryCode: 'AT',
      flagEmoji: '🇦🇹',
      subtitle: 'Vienne, Autriche',
      lat: 48.2082,
      lng: 16.3738,
    ),
    DestinationItem(
      name: 'Florence',
      country: 'Italie',
      countryCode: 'IT',
      flagEmoji: '🇮🇹',
      subtitle: 'Toscane, Italie',
      lat: 43.7696,
      lng: 11.2558,
    ),
    DestinationItem(
      name: 'Venise',
      country: 'Italie',
      countryCode: 'IT',
      flagEmoji: '🇮🇹',
      subtitle: 'Vénétie, Italie',
      lat: 45.4408,
      lng: 12.3155,
    ),
    DestinationItem(
      name: 'Le Cap',
      country: 'Afrique du Sud',
      countryCode: 'ZA',
      flagEmoji: '🇿🇦',
      subtitle: 'Cap-Occidental, Afrique du Sud',
      lat: -33.9249,
      lng: 18.4241,
    ),
    DestinationItem(
      name: 'Buenos Aires',
      country: 'Argentine',
      countryCode: 'AR',
      flagEmoji: '🇦🇷',
      subtitle: 'Buenos Aires, Argentine',
      lat: -34.6037,
      lng: -58.3816,
    ),
    DestinationItem(
      name: 'Mexico',
      country: 'Mexique',
      countryCode: 'MX',
      flagEmoji: '🇲🇽',
      subtitle: 'Valle de México, Mexique',
      lat: 19.4326,
      lng: -99.1332,
    ),
    DestinationItem(
      name: 'San Francisco',
      country: 'États-Unis',
      countryCode: 'US',
      flagEmoji: '🇺🇸',
      subtitle: 'Californie, USA',
      lat: 37.7749,
      lng: -122.4194,
    ),
    DestinationItem(
      name: 'Los Angeles',
      country: 'États-Unis',
      countryCode: 'US',
      flagEmoji: '🇺🇸',
      subtitle: 'Californie, USA',
      lat: 34.0522,
      lng: -118.2437,
    ),
    DestinationItem(
      name: 'Bali',
      country: 'Indonésie',
      countryCode: 'ID',
      flagEmoji: '🇮🇩',
      subtitle: 'Petites îles de la Sonde, Indonésie',
      lat: -8.4095,
      lng: 115.1889,
    ),
    DestinationItem(
      name: 'Istanbul',
      country: 'Turquie',
      countryCode: 'TR',
      flagEmoji: '🇹🇷',
      subtitle: 'Marmara, Turquie',
      lat: 41.0082,
      lng: 28.9784,
    ),
    DestinationItem(
      name: 'Bruxelles',
      country: 'Belgique',
      countryCode: 'BE',
      flagEmoji: '🇧🇪',
      subtitle: 'Bruxelles-Capitale, Belgique',
      lat: 50.8503,
      lng: 4.3517,
    ),
    DestinationItem(
      name: 'Genève',
      country: 'Suisse',
      countryCode: 'CH',
      flagEmoji: '🇨🇭',
      subtitle: 'Canton de Genève, Suisse',
      lat: 46.2044,
      lng: 6.1432,
    ),
  ];

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .trim();
  }

  /// Search destinations with instant in-memory matching and geocoding fallback
  Future<List<DestinationItem>> search(String query) async {
    final clean = _normalize(query);
    if (clean.isEmpty) {
      return popularDestinations;
    }

    final matched = _allPresets.where((item) {
      final nameNorm = _normalize(item.name);
      final countryNorm = _normalize(item.country);
      final subtitleNorm = _normalize(item.subtitle);
      return nameNorm.contains(clean) ||
          countryNorm.contains(clean) ||
          subtitleNorm.contains(clean);
    }).toList();

    if (matched.length >= 3 || clean.length < 3) {
      return matched;
    }

    // Geocoding fallback via OpenStreetMap Nominatim
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'VoyagoApp/2.0 (contact@voyago.app)',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final remoteItems = <DestinationItem>[];

        for (final item in data) {
          final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;
          final addr = item['address'] as Map<String, dynamic>? ?? {};

          final cityName = (item['name'] as String?)?.isNotEmpty == true
              ? item['name'] as String
              : (addr['city'] ??
                  addr['town'] ??
                  addr['municipality'] ??
                  addr['village'] ??
                  (item['display_name'] as String).split(',').first);

          final country = addr['country'] as String? ?? '';
          final code = (addr['country_code'] as String? ?? '').toUpperCase();
          final state = addr['state'] as String? ?? addr['county'] as String? ?? '';
          final subtitle = state.isNotEmpty && country.isNotEmpty
              ? '$state, $country'
              : country.isNotEmpty
                  ? country
                  : item['display_name'] as String;

          // Avoid duplicating already matched preset
          final alreadyPreset = matched.any(
            (p) => _normalize(p.name) == _normalize(cityName),
          );
          if (!alreadyPreset) {
            remoteItems.add(
              DestinationItem(
                name: cityName,
                country: country,
                countryCode: code,
                flagEmoji: countryCodeToEmoji(code),
                subtitle: subtitle,
                lat: lat,
                lng: lon,
              ),
            );
          }
        }

        return [...matched, ...remoteItems];
      }
    } catch (_) {}

    return matched;
  }
}
