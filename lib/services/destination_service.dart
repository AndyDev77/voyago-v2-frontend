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

  String get fullTitle => country.isNotEmpty && name != country ? '$name, $country' : name;
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
      name: 'Conakry',
      country: 'Guinée',
      countryCode: 'GN',
      flagEmoji: '🇬🇳',
      subtitle: 'Capitale, Guinée',
      lat: 9.6412,
      lng: -13.5784,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Abidjan',
      country: 'Côte d\'Ivoire',
      countryCode: 'CI',
      flagEmoji: '🇨🇮',
      subtitle: 'Lagunes, Côte d\'Ivoire',
      lat: 5.3600,
      lng: -4.0083,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Dakar',
      country: 'Sénégal',
      countryCode: 'SN',
      flagEmoji: '🇸🇳',
      subtitle: 'Cap-Vert, Sénégal',
      lat: 14.7167,
      lng: -17.4677,
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
      name: 'New York',
      country: 'États-Unis',
      countryCode: 'US',
      flagEmoji: '🇺🇸',
      subtitle: 'New York, USA',
      lat: 40.7128,
      lng: -74.0060,
      isPopular: true,
    ),
  ];

  static const List<DestinationItem> _allPresets = [
    ...popularDestinations,

    // --- GUINÉE (GN) ---
    DestinationItem(
      name: 'Kindia',
      country: 'Guinée',
      countryCode: 'GN',
      flagEmoji: '🇬🇳',
      subtitle: 'Basse-Guinée · Cité des agrumes & Voile de la mariée',
      lat: 10.0569,
      lng: -12.8658,
    ),
    DestinationItem(
      name: 'Kankan',
      country: 'Guinée',
      countryCode: 'GN',
      flagEmoji: '🇬🇳',
      subtitle: 'Haute-Guinée · Cité du Nabaya & Milo',
      lat: 10.3854,
      lng: -9.3057,
    ),
    DestinationItem(
      name: 'Labé',
      country: 'Guinée',
      countryCode: 'GN',
      flagEmoji: '🇬🇳',
      subtitle: 'Moyenne-Guinée · Capitale du Fouta Djallon & Chutes de Saala',
      lat: 11.3181,
      lng: -12.2895,
    ),
    DestinationItem(
      name: 'Boké',
      country: 'Guinée',
      countryCode: 'GN',
      flagEmoji: '🇬🇳',
      subtitle: 'Basse-Guinée · Rio Nunez & Fort de Boké',
      lat: 10.9409,
      lng: -14.2967,
    ),
    DestinationItem(
      name: 'Mamou',
      country: 'Guinée',
      countryCode: 'GN',
      flagEmoji: '🇬🇳',
      subtitle: 'Moyenne-Guinée · Ville carrefour',
      lat: 10.3755,
      lng: -12.0915,
    ),
    DestinationItem(
      name: 'Îles de Loos',
      country: 'Guinée',
      countryCode: 'GN',
      flagEmoji: '🇬🇳',
      subtitle: 'Kassa & Roume · Archipel paradisiaque, Guinée',
      lat: 9.5083,
      lng: -13.7917,
    ),
    DestinationItem(
      name: 'Guinée',
      country: 'Guinée',
      countryCode: 'GN',
      flagEmoji: '🇬🇳',
      subtitle: 'Pays · Afrique de l\'Ouest',
      lat: 9.9456,
      lng: -9.6966,
    ),

    // --- CÔTE D'IVOIRE (CI) ---
    DestinationItem(
      name: 'Abidjan',
      country: 'Côte d\'Ivoire',
      countryCode: 'CI',
      flagEmoji: '🇨🇮',
      subtitle: 'Lagunes · Perle des Lagunes, Plateau, Cocody',
      lat: 5.3600,
      lng: -4.0083,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Yamoussoukro',
      country: 'Côte d\'Ivoire',
      countryCode: 'CI',
      flagEmoji: '🇨🇮',
      subtitle: 'Capitale politique · Basilique Notre-Dame de la Paix',
      lat: 6.8276,
      lng: -5.2893,
    ),
    DestinationItem(
      name: 'Grand-Bassam',
      country: 'Côte d\'Ivoire',
      countryCode: 'CI',
      flagEmoji: '🇨🇮',
      subtitle: 'Ville historique UNESCO & Plages',
      lat: 5.2117,
      lng: -3.7388,
    ),
    DestinationItem(
      name: 'Assinie',
      country: 'Côte d\'Ivoire',
      countryCode: 'CI',
      flagEmoji: '🇨🇮',
      subtitle: 'Station balnéaire & Lagune Aby',
      lat: 5.1325,
      lng: -3.2842,
    ),
    DestinationItem(
      name: 'San-Pédro',
      country: 'Côte d\'Ivoire',
      countryCode: 'CI',
      flagEmoji: '🇨🇮',
      subtitle: 'Bas-Sassandra · Plages & Port',
      lat: 4.7485,
      lng: -6.6363,
    ),
    DestinationItem(
      name: 'Bouaké',
      country: 'Côte d\'Ivoire',
      countryCode: 'CI',
      flagEmoji: '🇨🇮',
      subtitle: 'Vallée du Bandama · Centre',
      lat: 7.6905,
      lng: -5.0300,
    ),
    DestinationItem(
      name: 'Côte d\'Ivoire',
      country: 'Côte d\'Ivoire',
      countryCode: 'CI',
      flagEmoji: '🇨🇮',
      subtitle: 'Pays · Afrique de l\'Ouest',
      lat: 7.5400,
      lng: -5.5471,
    ),

    // --- SÉNÉGAL (SN) ---
    DestinationItem(
      name: 'Dakar',
      country: 'Sénégal',
      countryCode: 'SN',
      flagEmoji: '🇸🇳',
      subtitle: 'Capitale · Île de Gorée, Almadies, Monument Renaissance',
      lat: 14.7167,
      lng: -17.4677,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Saint-Louis',
      country: 'Sénégal',
      countryCode: 'SN',
      flagEmoji: '🇸🇳',
      subtitle: 'Cité coloniale UNESCO & Fleuve Sénégal',
      lat: 16.0326,
      lng: -16.4818,
    ),
    DestinationItem(
      name: 'Saly',
      country: 'Sénégal',
      countryCode: 'SN',
      flagEmoji: '🇸🇳',
      subtitle: 'Petite-Côte · Plages, Resorts & Pêche',
      lat: 14.4431,
      lng: -17.0272,
    ),
    DestinationItem(
      name: 'Cap Skirring',
      country: 'Sénégal',
      countryCode: 'SN',
      flagEmoji: '🇸🇳',
      subtitle: 'Casamance · Plages sauvages & Forêts de palmiers',
      lat: 12.3550,
      lng: -16.7461,
    ),
    DestinationItem(
      name: 'Sénégal',
      country: 'Sénégal',
      countryCode: 'SN',
      flagEmoji: '🇸🇳',
      subtitle: 'Pays de la Teranga · Afrique de l\'Ouest',
      lat: 14.4974,
      lng: -14.4524,
    ),

    // --- MALI (ML) ---
    DestinationItem(
      name: 'Bamako',
      country: 'Mali',
      countryCode: 'ML',
      flagEmoji: '🇲🇱',
      subtitle: 'Capitale · Les rives du Niger',
      lat: 12.6392,
      lng: -8.0029,
    ),
    DestinationItem(
      name: 'Djenné',
      country: 'Mali',
      countryCode: 'ML',
      flagEmoji: '🇲🇱',
      subtitle: 'Grande Mosquée en banco UNESCO',
      lat: 13.9056,
      lng: -4.5533,
    ),
    DestinationItem(
      name: 'Mali',
      country: 'Mali',
      countryCode: 'ML',
      flagEmoji: '🇲🇱',
      subtitle: 'Pays · Afrique de l\'Ouest',
      lat: 17.5707,
      lng: -3.9962,
    ),

    // --- CAMEROUN (CM) ---
    DestinationItem(
      name: 'Douala',
      country: 'Cameroun',
      countryCode: 'CM',
      flagEmoji: '🇨🇲',
      subtitle: 'Littoral · Poumon économique',
      lat: 4.0511,
      lng: 9.7679,
    ),
    DestinationItem(
      name: 'Yaoundé',
      country: 'Cameroun',
      countryCode: 'CM',
      flagEmoji: '🇨🇲',
      subtitle: 'Capitale aux 7 collines',
      lat: 3.8480,
      lng: 11.5021,
    ),
    DestinationItem(
      name: 'Kribi',
      country: 'Cameroun',
      countryCode: 'CM',
      flagEmoji: '🇨🇲',
      subtitle: 'Sud · Chutes de la Lobé & Plages de sable blanc',
      lat: 2.9372,
      lng: 9.9103,
    ),
    DestinationItem(
      name: 'Cameroun',
      country: 'Cameroun',
      countryCode: 'CM',
      flagEmoji: '🇨🇲',
      subtitle: 'Afrique en miniature · Afrique centrale',
      lat: 7.3697,
      lng: 12.3547,
    ),

    // --- BÉNIN (BJ) & TOGO (TG) ---
    DestinationItem(
      name: 'Cotonou',
      country: 'Bénin',
      countryCode: 'BJ',
      flagEmoji: '🇧🇯',
      subtitle: 'Littoral · Dantokpa & Étoile rouge',
      lat: 6.3703,
      lng: 2.4183,
    ),
    DestinationItem(
      name: 'Ouidah',
      country: 'Bénin',
      countryCode: 'BJ',
      flagEmoji: '🇧🇯',
      subtitle: 'Cité historique & Berceau du Vaudou',
      lat: 6.3631,
      lng: 2.0851,
    ),
    DestinationItem(
      name: 'Lomé',
      country: 'Togo',
      countryCode: 'TG',
      flagEmoji: '🇹🇬',
      subtitle: 'Maritime · Boulevard circulaire & Marché des fétiches',
      lat: 6.1375,
      lng: 1.2123,
    ),

    // --- MAROC (MA) ---
    DestinationItem(
      name: 'Marrakech',
      country: 'Maroc',
      countryCode: 'MA',
      flagEmoji: '🇲🇦',
      subtitle: 'Médina, Jemaa el-Fna & Jardin Majorelle',
      lat: 31.6295,
      lng: -7.9811,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Casablanca',
      country: 'Maroc',
      countryCode: 'MA',
      flagEmoji: '🇲🇦',
      subtitle: 'Mosquée Hassan II & Corniche d\'Aïn Diab',
      lat: 33.5731,
      lng: -7.5898,
    ),
    DestinationItem(
      name: 'Fès',
      country: 'Maroc',
      countryCode: 'MA',
      flagEmoji: '🇲🇦',
      subtitle: 'Fès el-Bali · Cité spirituelle UNESCO',
      lat: 34.0181,
      lng: -5.0078,
    ),
    DestinationItem(
      name: 'Chefchaouen',
      country: 'Maroc',
      countryCode: 'MA',
      flagEmoji: '🇲🇦',
      subtitle: 'La perle bleue du Rif',
      lat: 35.1716,
      lng: -5.2697,
    ),
    DestinationItem(
      name: 'Tanger',
      country: 'Maroc',
      countryCode: 'MA',
      flagEmoji: '🇲🇦',
      subtitle: 'Détroit de Gibraltar & Cap Spartel',
      lat: 35.7595,
      lng: -5.8340,
    ),
    DestinationItem(
      name: 'Agadir',
      country: 'Maroc',
      countryCode: 'MA',
      flagEmoji: '🇲🇦',
      subtitle: 'Baie d\'Agadir, Surf & Taghazout',
      lat: 30.4278,
      lng: -9.5981,
    ),
    DestinationItem(
      name: 'Maroc',
      country: 'Maroc',
      countryCode: 'MA',
      flagEmoji: '🇲🇦',
      subtitle: 'Royaume du Maroc · Afrique du Nord',
      lat: 31.7917,
      lng: -7.0926,
    ),

    // --- TUNISIE & ALGÉRIE ---
    DestinationItem(
      name: 'Tunis',
      country: 'Tunisie',
      countryCode: 'TN',
      flagEmoji: '🇹🇳',
      subtitle: 'Médina, Carthage & Sidi Bou Saïd',
      lat: 36.8065,
      lng: 10.1815,
    ),
    DestinationItem(
      name: 'Djerba',
      country: 'Tunisie',
      countryCode: 'TN',
      flagEmoji: '🇹🇳',
      subtitle: 'Île des Lotophages & Houmt Souk',
      lat: 33.8076,
      lng: 10.8451,
    ),
    DestinationItem(
      name: 'Alger',
      country: 'Algérie',
      countryCode: 'DZ',
      flagEmoji: '🇩🇿',
      subtitle: 'Alger la Blanche · Casbah & Baie',
      lat: 36.7538,
      lng: 3.0588,
    ),

    // --- FRANCE (FR) ---
    DestinationItem(
      name: 'Paris',
      country: 'France',
      countryCode: 'FR',
      flagEmoji: '🇫🇷',
      subtitle: 'Île-de-France · Tour Eiffel, Louvre, Montmartre',
      lat: 48.8566,
      lng: 2.3522,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Nice',
      country: 'France',
      countryCode: 'FR',
      flagEmoji: '🇫🇷',
      subtitle: 'Côte d\'Azur · Promenade des Anglais',
      lat: 43.7102,
      lng: 7.2620,
    ),
    DestinationItem(
      name: 'Lyon',
      country: 'France',
      countryCode: 'FR',
      flagEmoji: '🇫🇷',
      subtitle: 'Capitale de la gastronomie · Vieux Lyon & Fourvière',
      lat: 45.7640,
      lng: 4.8357,
    ),
    DestinationItem(
      name: 'Marseille',
      country: 'France',
      countryCode: 'FR',
      flagEmoji: '🇫🇷',
      subtitle: 'Vieux-Port, Calanques & Notre-Dame de la Garde',
      lat: 43.2965,
      lng: 5.3698,
    ),
    DestinationItem(
      name: 'Bordeaux',
      country: 'France',
      countryCode: 'FR',
      flagEmoji: '🇫🇷',
      subtitle: 'Cité du Vin & Place de la Bourse',
      lat: 44.8378,
      lng: -0.5792,
    ),
    DestinationItem(
      name: 'Strasbourg',
      country: 'France',
      countryCode: 'FR',
      flagEmoji: '🇫🇷',
      subtitle: 'Petite France & Cathédrale',
      lat: 48.5734,
      lng: 7.7521,
    ),
    DestinationItem(
      name: 'France',
      country: 'France',
      countryCode: 'FR',
      flagEmoji: '🇫🇷',
      subtitle: 'Toutes destinations · Europe',
      lat: 46.2276,
      lng: 2.2137,
    ),

    // --- ITALIE (IT) ---
    DestinationItem(
      name: 'Rome',
      country: 'Italie',
      countryCode: 'IT',
      flagEmoji: '🇮🇹',
      subtitle: 'Colisée, Fontaine de Trevi & Vatican',
      lat: 41.9028,
      lng: 12.4964,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Florence',
      country: 'Italie',
      countryCode: 'IT',
      flagEmoji: '🇮🇹',
      subtitle: 'Toscane · Duomo & Galerie des Offices',
      lat: 43.7696,
      lng: 11.2558,
    ),
    DestinationItem(
      name: 'Venise',
      country: 'Italie',
      countryCode: 'IT',
      flagEmoji: '🇮🇹',
      subtitle: 'Grand Canal & Place Saint-Marc',
      lat: 45.4408,
      lng: 12.3155,
    ),
    DestinationItem(
      name: 'Milan',
      country: 'Italie',
      countryCode: 'IT',
      flagEmoji: '🇮🇹',
      subtitle: 'Lombardie · Duomo & Mode',
      lat: 45.4642,
      lng: 9.1900,
    ),
    DestinationItem(
      name: 'Naples',
      country: 'Italie',
      countryCode: 'IT',
      flagEmoji: '🇮🇹',
      subtitle: 'Campanie · Pompéi & Vésuve',
      lat: 40.8518,
      lng: 14.2681,
    ),
    DestinationItem(
      name: 'Italie',
      country: 'Italie',
      countryCode: 'IT',
      flagEmoji: '🇮🇹',
      subtitle: 'Pays · Europe',
      lat: 41.8719,
      lng: 12.5674,
    ),

    // --- ESPAGNE (ES) ---
    DestinationItem(
      name: 'Barcelone',
      country: 'Espagne',
      countryCode: 'ES',
      flagEmoji: '🇪🇸',
      subtitle: 'Sagrada Família & Parc Güell',
      lat: 41.3851,
      lng: 2.1734,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Madrid',
      country: 'Espagne',
      countryCode: 'ES',
      flagEmoji: '🇪🇸',
      subtitle: 'Musée du Prado & Gran Vía',
      lat: 40.4168,
      lng: -3.7038,
    ),
    DestinationItem(
      name: 'Séville',
      country: 'Espagne',
      countryCode: 'ES',
      flagEmoji: '🇪🇸',
      subtitle: 'Andalousie · Alcazar & Plaza de España',
      lat: 37.3891,
      lng: -5.9845,
    ),
    DestinationItem(
      name: 'Espagne',
      country: 'Espagne',
      countryCode: 'ES',
      flagEmoji: '🇪🇸',
      subtitle: 'Pays · Péninsule Ibérique',
      lat: 40.4637,
      lng: -3.7492,
    ),

    // --- JAPON (JP) ---
    DestinationItem(
      name: 'Tokyo',
      country: 'Japon',
      countryCode: 'JP',
      flagEmoji: '🇯🇵',
      subtitle: 'Shibuya, Shinjuku & Senso-ji',
      lat: 35.6762,
      lng: 139.6503,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Kyoto',
      country: 'Japon',
      countryCode: 'JP',
      flagEmoji: '🇯🇵',
      subtitle: 'Kinkaku-ji, Fushimi Inari & Gion',
      lat: 35.0116,
      lng: 135.7681,
    ),
    DestinationItem(
      name: 'Osaka',
      country: 'Japon',
      countryCode: 'JP',
      flagEmoji: '🇯🇵',
      subtitle: 'Dotonbori & Château d\'Osaka',
      lat: 34.6937,
      lng: 135.5023,
    ),
    DestinationItem(
      name: 'Japon',
      country: 'Japon',
      countryCode: 'JP',
      flagEmoji: '🇯🇵',
      subtitle: 'Pays · Asie de l\'Est',
      lat: 36.2048,
      lng: 138.2529,
    ),

    // --- AUTRES DESTINATIONS MONDIALES ---
    DestinationItem(
      name: 'Londres',
      country: 'Royaume-Uni',
      countryCode: 'GB',
      flagEmoji: '🇬🇧',
      subtitle: 'Big Ben, London Eye & British Museum',
      lat: 51.5074,
      lng: -0.1278,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Lisbonne',
      country: 'Portugal',
      countryCode: 'PT',
      flagEmoji: '🇵🇹',
      subtitle: 'Belém, Alfama & Tram 28',
      lat: 38.7223,
      lng: -9.1393,
    ),
    DestinationItem(
      name: 'Amsterdam',
      country: 'Pays-Bas',
      countryCode: 'NL',
      flagEmoji: '🇳🇱',
      subtitle: 'Canaux, Rijksmuseum & Jordaan',
      lat: 52.3676,
      lng: 4.9041,
    ),
    DestinationItem(
      name: 'Berlin',
      country: 'Allemagne',
      countryCode: 'DE',
      flagEmoji: '🇩🇪',
      subtitle: 'Porte de Brandebourg & Mur de Berlin',
      lat: 52.5200,
      lng: 13.4050,
    ),
    DestinationItem(
      name: 'Bruxelles',
      country: 'Belgique',
      countryCode: 'BE',
      flagEmoji: '🇧🇪',
      subtitle: 'Grand-Place, Atomium & Manneken-Pis',
      lat: 50.8503,
      lng: 4.3517,
    ),
    DestinationItem(
      name: 'Genève',
      country: 'Suisse',
      countryCode: 'CH',
      flagEmoji: '🇨🇭',
      subtitle: 'Jet d\'eau & Lac Léman',
      lat: 46.2044,
      lng: 6.1432,
    ),
    DestinationItem(
      name: 'Dubai',
      country: 'Émirats Arabes Unis',
      countryCode: 'AE',
      flagEmoji: '🇦🇪',
      subtitle: 'Burj Khalifa, Dubai Mall & Marina',
      lat: 25.2048,
      lng: 55.2708,
      isPopular: true,
    ),
    DestinationItem(
      name: 'Bangkok',
      country: 'Thaïlande',
      countryCode: 'TH',
      flagEmoji: '🇹🇭',
      subtitle: 'Grand Palais, Wat Arun & Street Food',
      lat: 13.7563,
      lng: 100.5018,
    ),
    DestinationItem(
      name: 'Bali',
      country: 'Indonésie',
      countryCode: 'ID',
      flagEmoji: '🇮🇩',
      subtitle: 'Ubud, Canggu & Rizières de Tegalalang',
      lat: -8.4095,
      lng: 115.1889,
    ),
    DestinationItem(
      name: 'Montréal',
      country: 'Canada',
      countryCode: 'CA',
      flagEmoji: '🇨🇦',
      subtitle: 'Vieux-Montréal & Mont Royal',
      lat: 45.5017,
      lng: -73.5673,
    ),
    DestinationItem(
      name: 'Le Cap',
      country: 'Afrique du Sud',
      countryCode: 'ZA',
      flagEmoji: '🇿🇦',
      subtitle: 'Table Mountain & Robben Island',
      lat: -33.9249,
      lng: 18.4241,
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
        .replaceAll('-', ' ')
        .replaceAll('\'', ' ')
        .trim();
  }

  /// Recherche intelligente de destinations (villes & pays) avec tri optimisé
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

    // Tri contextuel :
    // 1. Si la requête correspond au pays (ex: "guine"), on affiche en priorité les VILLES de ce pays !
    // 2. Les correspondances exactes ou commençant par la requête passent en tête
    // 3. Les villes populaires sont mises en valeur
    matched.sort((a, b) {
      final aName = _normalize(a.name);
      final bName = _normalize(b.name);
      final aCountry = _normalize(a.country);
      final bCountry = _normalize(b.country);

      final aIsCountryOnly = a.name.toLowerCase() == a.country.toLowerCase();
      final bIsCountryOnly = b.name.toLowerCase() == b.country.toLowerCase();

      // Si l'utilisateur tape le nom d'un pays (ex: "guine"), on affiche d'abord les VILLES de ce pays !
      if (aCountry.contains(clean) && bCountry.contains(clean)) {
        if (!aIsCountryOnly && bIsCountryOnly) return -1; // Ville avant le pays seul
        if (aIsCountryOnly && !bIsCountryOnly) return 1;
      }

      // Exact match sur le nom de ville
      if (aName == clean && bName != clean) return -1;
      if (bName == clean && aName != clean) return 1;

      // Nom commençant par la requête
      final aStarts = aName.startsWith(clean);
      final bStarts = bName.startsWith(clean);
      if (aStarts && !bStarts) return -1;
      if (bStarts && !aStarts) return 1;

      if (a.isPopular && !b.isPopular) return -1;
      if (!a.isPopular && b.isPopular) return 1;

      return aName.compareTo(bName);
    });

    if (matched.length >= 3 || clean.length < 3) {
      return matched;
    }

    // Fallback géocodage OpenStreetMap Nominatim pour les villes moins courantes
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=6&addressdetails=1',
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
