import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/day_weather.dart';

class CityLocation {
  final String name;
  final String country;
  final double lat;
  final double lng;

  const CityLocation({
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
  });

  String get displayName => country.isNotEmpty ? '$name, $country' : name;
}

class LiveWeatherService {
  LiveWeatherService._();
  static final LiveWeatherService instance = LiveWeatherService._();

  static const List<CityLocation> _presetCities = [
    CityLocation(name: 'Paris', country: 'France', lat: 48.8566, lng: 2.3522),
    CityLocation(name: 'Tokyo', country: 'Japon', lat: 35.6762, lng: 139.6503),
    CityLocation(name: 'Rome', country: 'Italie', lat: 41.9028, lng: 12.4964),
    CityLocation(name: 'Barcelone', country: 'Espagne', lat: 41.3851, lng: 2.1734),
    CityLocation(name: 'New York', country: 'USA', lat: 40.7128, lng: -74.0060),
    CityLocation(name: 'Londres', country: 'Royaume-Uni', lat: 51.5074, lng: -0.1278),
    CityLocation(name: 'Dubai', country: 'Émirats', lat: 25.2048, lng: 55.2708),
    CityLocation(name: 'Bangkok', country: 'Thaïlande', lat: 13.7563, lng: 100.5018),
    CityLocation(name: 'Sydney', country: 'Australie', lat: -33.8688, lng: 151.2093),
    CityLocation(name: 'Berlin', country: 'Allemagne', lat: 52.5200, lng: 13.4050),
    CityLocation(name: 'Amsterdam', country: 'Pays-Bas', lat: 52.3676, lng: 4.9041),
    CityLocation(name: 'Marrakech', country: 'Maroc', lat: 31.6295, lng: -7.9811),
    CityLocation(name: 'Abidjan', country: 'Côte d\'Ivoire', lat: 5.3600, lng: -4.0083),
    CityLocation(name: 'Dakar', country: 'Sénégal', lat: 14.7167, lng: -17.4677),
  ];

  /// Find a city by query, checks preset first, then queries OpenStreetMap Nominatim
  Future<List<CityLocation>> searchCities(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return _presetCities.take(5).toList();

    // Check presets first
    final matchedPresets = _presetCities
        .where((c) =>
            c.name.toLowerCase().contains(clean) ||
            c.country.toLowerCase().contains(clean))
        .toList();

    if (matchedPresets.isNotEmpty) {
      return matchedPresets;
    }

    // Call Nominatim Geocoding
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1');
      final res = await http.get(url, headers: {
        'User-Agent': 'VoyagoApp/1.0',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((item) {
          final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;
          final name = (item['name'] as String?)?.isNotEmpty == true
              ? item['name'] as String
              : (item['display_name'] as String).split(',').first;
          final country = item['address']?['country'] as String? ?? '';
          return CityLocation(
            name: name,
            country: country,
            lat: lat,
            lng: lon,
          );
        }).toList();
      }
    } catch (_) {}

    return matchedPresets;
  }

  /// Fetches real-time weather from Open-Meteo for any latitude/longitude
  Future<List<DayWeather>> fetchWeather(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final daily = data['daily'];
        if (daily != null) {
          final dates = daily['time'] as List? ?? [];
          final codes = daily['weather_code'] as List? ?? [];
          final maxTemps = daily['temperature_2m_max'] as List? ?? [];
          final minTemps = daily['temperature_2m_min'] as List? ?? [];

          final List<DayWeather> list = [];
          for (var i = 0; i < dates.length; i++) {
            final code = (codes[i] as num?)?.toInt() ?? 0;
            final maxT = (maxTemps[i] as num?)?.toDouble() ?? 20.0;
            final minT = (minTemps[i] as num?)?.toDouble() ?? 14.0;
            list.add(DayWeather(
              date: dates[i].toString(),
              icon: _weatherCodeToIcon(code),
              summary: _weatherCodeToSummary(code),
              weatherCode: code,
              tempMax: maxT,
              tempMin: minT,
            ));
          }
          return list;
        }
      }
    } catch (_) {}

    // Fallback default sunny day
    return [
      const DayWeather(
        date: 'Aujourd\'hui',
        icon: '☀️',
        summary: 'Ensoleillé',
        weatherCode: 0,
        tempMax: 22.0,
        tempMin: 15.0,
      )
    ];
  }

  static String _weatherCodeToIcon(int code) {
    if (code >= 95) return '⛈️';
    if (code >= 80) return '🌧️';
    if (code >= 71) return '❄️';
    if (code >= 61) return '🌧️';
    if (code >= 51) return '🌦️';
    if (code >= 45) return '🌫️';
    if (code >= 3) return '☁️';
    if (code >= 1) return '⛅';
    return '☀️';
  }

  static String _weatherCodeToSummary(int code) {
    if (code >= 95) return 'Orages';
    if (code >= 80) return 'Averses de pluie';
    if (code >= 71) return 'Chutes de neige';
    if (code >= 61) return 'Pluie continue';
    if (code >= 51) return 'Bruine';
    if (code >= 45) return 'Brouillard';
    if (code >= 3) return 'Très nuageux';
    if (code >= 1) return 'Partiellement nuageux';
    return 'Ciel dégagé et ensoleillé';
  }
}
