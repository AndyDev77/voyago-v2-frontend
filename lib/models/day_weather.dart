class DayWeather {
  final String date;
  final String icon;
  final String summary;
  final int weatherCode;
  final double tempMax;
  final double tempMin;

  const DayWeather({
    required this.date,
    required this.icon,
    required this.summary,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
  });

  bool get hasPrecipitation =>
      (weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 80 && weatherCode <= 82) ||
      (weatherCode >= 71 && weatherCode <= 77) ||
      (weatherCode >= 85 && weatherCode <= 86) ||
      weatherCode >= 95;

  bool get isRainy =>
      (weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 80 && weatherCode <= 82);

  bool get isSnowy =>
      (weatherCode >= 71 && weatherCode <= 77) ||
      (weatherCode >= 85 && weatherCode <= 86);

  bool get isThunderstorm => weatherCode >= 95;

  bool get isFoggy => weatherCode == 45 || weatherCode == 48;

  bool get showClouds =>
      weatherCode == 1 ||
      weatherCode == 2 ||
      weatherCode == 3 ||
      isFoggy ||
      hasPrecipitation;


  factory DayWeather.fromJson(Map<String, dynamic> json) {
    return DayWeather(
      date: json['date']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '🌤',
      summary: json['summary']?.toString() ?? '',
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      tempMax: (json['temp_max'] as num?)?.toDouble() ?? 0.0,
      tempMin: (json['temp_min'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'icon': icon,
      'summary': summary,
      'weather_code': weatherCode,
      'temp_max': tempMax,
      'temp_min': tempMin,
    };
  }
}
