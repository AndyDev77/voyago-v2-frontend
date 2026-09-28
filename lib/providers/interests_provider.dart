import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';
import '../models/interest.dart';

final interestsApiProvider = Provider<InterestsApi>((ref) => InterestsApi());

/// Provider pour la liste des 10 catégories d'intérêts de voyage
final interestsProvider = FutureProvider<List<Interest>>((ref) async {
  final api = ref.watch(interestsApiProvider);
  return api.getInterests();
});
