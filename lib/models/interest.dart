class Interest {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final String? imageUrl;

  const Interest({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    this.imageUrl,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '🌍',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}
