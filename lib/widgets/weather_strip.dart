import 'package:flutter/material.dart';
import '../models/day_weather.dart';
import '../theme.dart';

class WeatherStrip extends StatelessWidget {
  final List<DayWeather> weather;
  final int selectedDay;

  const WeatherStrip({
    super.key,
    required this.weather,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    if (weather.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 80,
      color: VoyagoColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: weather.length,
        itemBuilder: (context, index) {
          final w = weather[index];
          final isSelected = index + 1 == selectedDay;
          return _WeatherDay(
            weather: w,
            dayNumber: index + 1,
            isSelected: isSelected,
          );
        },
      ),
    );
  }
}

class _WeatherDay extends StatelessWidget {
  final DayWeather weather;
  final int dayNumber;
  final bool isSelected;

  const _WeatherDay({
    required this.weather,
    required this.dayNumber,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? VoyagoColors.primary.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? VoyagoColors.primary : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'J$dayNumber',
            style: TextStyle(
              color: isSelected ? VoyagoColors.primary : VoyagoColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            weather.icon,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '${weather.tempMax.round()}°',
            style: TextStyle(
              color: isSelected ? VoyagoColors.text : VoyagoColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${weather.tempMin.round()}°',
            style: const TextStyle(
              color: VoyagoColors.muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
