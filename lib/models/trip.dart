import 'poi.dart';
import 'day_weather.dart';

class Trip {
  final String id;
  final String userId;
  final String destination;
  final String pace;
  final String budget;
  final int durationDays;
  final List<String> transports;
  final List<String> interests;
  final List<POI> pois;
  final List<DayWeather> weather;
  final bool isPublic;
  final int likes;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.userId,
    required this.destination,
    required this.pace,
    required this.budget,
    required this.durationDays,
    required this.transports,
    required this.interests,
    required this.pois,
    required this.weather,
    required this.isPublic,
    required this.likes,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    List<POI> parsePois(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) => POI.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    List<DayWeather> parseWeather(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .map((e) => DayWeather.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    List<String> parseStringList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return Trip(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId:
          json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      pace: json['pace']?.toString() ?? '',
      budget: json['budget']?.toString() ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ??
          (json['durationDays'] as num?)?.toInt() ??
          1,
      transports: parseStringList(json['transports']),
      interests: parseStringList(json['interests']),
      pois: parsePois(json['pois']),
      weather: parseWeather(json['weather']),
      isPublic: json['is_public'] as bool? ?? json['isPublic'] as bool? ?? false,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'destination': destination,
      'pace': pace,
      'budget': budget,
      'duration_days': durationDays,
      'transports': transports,
      'interests': interests,
      'pois': pois.map((p) => p.toJson()).toList(),
      'weather': weather.map((w) => w.toJson()).toList(),
      'is_public': isPublic,
      'likes': likes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  List<POI> poisForDay(int day) {
    final filtered = pois.where((p) => p.day == day).toList();
    filtered.sort((a, b) => a.order.compareTo(b.order));
    return filtered;
  }

  POI? get firstPoiWithImage {
    try {
      return pois.firstWhere((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty);
    } catch (_) {
      return pois.isNotEmpty ? pois.first : null;
    }
  }
}
