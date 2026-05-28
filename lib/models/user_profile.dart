class UserProfile {
  final String userId;
  final String name;
  final String? pseudo;
  final String? avatarEmoji;
  final String? country;
  final String? city;
  final int xp;
  final int level;
  final int streak;
  final int tripsCount;
  final List<String> badges;
  final DateTime lastActive;
  final bool isPro;
  final String? proTier;

  const UserProfile({
    required this.userId,
    required this.name,
    this.pseudo,
    this.avatarEmoji,
    this.country,
    this.city,
    required this.xp,
    required this.level,
    required this.streak,
    required this.tripsCount,
    required this.badges,
    required this.lastActive,
    required this.isPro,
    this.proTier,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> parseBadges(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return UserProfile(
      userId: json['user_id']?.toString() ??
          json['userId']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? 'Voyageur',
      pseudo: json['pseudo']?.toString(),
      avatarEmoji:
          json['avatar_emoji']?.toString() ?? json['avatarEmoji']?.toString(),
      country: json['country']?.toString(),
      city: json['city']?.toString(),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      tripsCount:
          (json['trips_count'] as num?)?.toInt() ??
          (json['tripsCount'] as num?)?.toInt() ??
          0,
      badges: parseBadges(json['badges']),
      lastActive: json['last_active'] != null
          ? DateTime.tryParse(json['last_active'].toString()) ?? DateTime.now()
          : json['lastActive'] != null
              ? DateTime.tryParse(json['lastActive'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      isPro: json['is_pro'] as bool? ?? json['isPro'] as bool? ?? false,
      proTier: json['pro_tier']?.toString() ?? json['proTier']?.toString(),
    );
  }

  int get xpInCurrentLevel => xp % 100;

  int get xpToNextLevel => 100 - xpInCurrentLevel;

  double get xpProgress => xpInCurrentLevel / 100.0;

  String get displayName => pseudo ?? name;

  String get avatarDisplay => avatarEmoji ?? '🦜';
}
