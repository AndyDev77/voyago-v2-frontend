/// Étoiles agrégées d'un lieu, issues des avis des voyageurs Voyago.
class PlaceStats {
  final String placeKey;
  final double? ratingAvg;
  final int reviewsCount;
  final int likesCount;
  final int? myRating;
  final bool myLiked;

  const PlaceStats({
    required this.placeKey,
    this.ratingAvg,
    this.reviewsCount = 0,
    this.likesCount = 0,
    this.myRating,
    this.myLiked = false,
  });

  factory PlaceStats.fromJson(Map<String, dynamic> json) {
    return PlaceStats(
      placeKey: json['place_key']?.toString() ?? '',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      myRating: (json['my_rating'] as num?)?.toInt(),
      myLiked: json['my_liked'] == true,
    );
  }

  bool get hasCommunityReviews => reviewsCount > 0 && ratingAvg != null;
}

/// Avis d'un voyageur sur un lieu (affiché aux autres voyageurs).
class PlaceReview {
  final String id;
  final int rating;
  final String comment;
  final bool liked;
  final String? authorName;
  final String? authorEmoji;
  final DateTime? updatedAt;

  const PlaceReview({
    required this.id,
    required this.rating,
    this.comment = '',
    this.liked = false,
    this.authorName,
    this.authorEmoji,
    this.updatedAt,
  });

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    final author = json['author'] is Map ? json['author'] as Map : const {};
    return PlaceReview(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      liked: json['liked'] == true,
      authorName: author['name']?.toString(),
      authorEmoji: author['avatar_emoji']?.toString(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal(),
    );
  }
}
