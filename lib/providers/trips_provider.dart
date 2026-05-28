import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip.dart';
import '../services/api_service.dart';

final tripsProvider = FutureProvider.family<List<Trip>, String>((ref, userId) async {
  if (userId.isEmpty) return [];
  return ApiService.instance.getTrips(userId);
});

final tripDetailProvider = FutureProvider.family<Trip, String>((ref, tripId) async {
  return ApiService.instance.getTrip(tripId);
});
