import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interest.dart';
import '../services/api_service.dart';

final interestsProvider = FutureProvider<List<Interest>>((ref) async {
  return ApiService.instance.getInterests();
});
