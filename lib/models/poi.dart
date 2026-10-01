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

  final double rating;
  final int reviewsCount;
  final String? insiderTip;

  /// Pépite secrète peu connue des touristes.
  final bool hiddenGem;

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
    this.rating = 4.7,
    this.reviewsCount = 1250,
    this.insiderTip,
    this.hiddenGem = false,
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
      rating: (json['rating'] as num?)?.toDouble() ?? 4.7,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 1250,
      insiderTip: json['insider_tip']?.toString(),
      hiddenGem: json['hidden_gem'] == true,
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
      'rating': rating,
      'reviews_count': reviewsCount,
      if (insiderTip != null) 'insider_tip': insiderTip,
      if (hiddenGem) 'hidden_gem': true,
    };
  }
}
