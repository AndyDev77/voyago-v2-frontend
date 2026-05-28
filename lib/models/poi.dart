class POI {
  final String name;
  final String description;
  final String category;
  final String imageQuery;
  final double lat;
  final double lng;
  final int day;
  final int order;
  final int durationMinutes;
  final String? imageUrl;

  const POI({
    required this.name,
    required this.description,
    required this.category,
    required this.imageQuery,
    required this.lat,
    required this.lng,
    required this.day,
    required this.order,
    required this.durationMinutes,
    this.imageUrl,
  });

  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageQuery: json['image_query']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      day: (json['day'] as num?)?.toInt() ?? 1,
      order: (json['order'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'image_query': imageQuery,
      'lat': lat,
      'lng': lng,
      'day': day,
      'order': order,
      'duration_minutes': durationMinutes,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}
