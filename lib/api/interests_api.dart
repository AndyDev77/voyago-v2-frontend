import '../models/interest.dart';
import 'dio_client.dart';
import 'endpoints.dart';

class InterestsApi {
  final DioClient _client;

  InterestsApi({DioClient? client}) : _client = client ?? DioClient.instance;

  /// Récupération des catégories d'intérêts de voyage
  Future<List<Interest>> getInterests() async {
    final data = await _client.get(Endpoints.interests);
    if (data is List) {
      return data.map((e) => Interest.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
