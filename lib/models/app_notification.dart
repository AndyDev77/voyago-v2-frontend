/// Notification Voyago (cloche) : arrivée sur un lieu, itinéraire prêt, etc.
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body = '',
    this.data = const {},
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : const {},
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
    );
  }

  bool get isArrival => type == 'arrival';
  bool get isReviewed => data['reviewed'] == true;
  String? get tripId => data['trip_id']?.toString();
  String? get placeName => data['place_name']?.toString();
  double? get lat => (data['lat'] as num?)?.toDouble();
  double? get lng => (data['lng'] as num?)?.toDouble();

  AppNotification copyWith({bool? read, Map<String, dynamic>? data}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data ?? this.data,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}
