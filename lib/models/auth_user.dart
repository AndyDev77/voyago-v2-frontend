class AuthUser {
  final String userId;
  final String authProvider;
  final String name;
  final String? email;
  final String? picture;
  final String? pseudo;
  final String? avatarEmoji;
  final String? dateOfBirth;
  final String? country;
  final String? city;
  final bool isPro;
  final String? proTier;
  final DateTime? proExpiresAt;

  const AuthUser({
    required this.userId,
    required this.authProvider,
    required this.name,
    this.email,
    this.picture,
    this.pseudo,
    this.avatarEmoji,
    this.dateOfBirth,
    this.country,
    this.city,
    required this.isPro,
    this.proTier,
    this.proExpiresAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['user_id']?.toString() ??
          json['userId']?.toString() ??
          json['id']?.toString() ??
          '',
      authProvider:
          json['auth_provider']?.toString() ?? json['authProvider']?.toString() ?? 'email',
      name: json['name']?.toString() ?? 'Voyageur',
      email: json['email']?.toString(),
      picture: json['picture']?.toString(),
      pseudo: json['pseudo']?.toString(),
      avatarEmoji: json['avatar_emoji']?.toString() ?? json['avatarEmoji']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString() ?? json['dateOfBirth']?.toString(),
      country: json['country']?.toString(),
      city: json['city']?.toString(),
      isPro: json['is_pro'] as bool? ?? json['isPro'] as bool? ?? false,
      proTier: json['pro_tier']?.toString() ?? json['proTier']?.toString(),
      proExpiresAt: json['pro_expires_at'] != null
          ? DateTime.tryParse(json['pro_expires_at'].toString())
          : json['proExpiresAt'] != null
              ? DateTime.tryParse(json['proExpiresAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'auth_provider': authProvider,
      'name': name,
      if (email != null) 'email': email,
      if (picture != null) 'picture': picture,
      if (pseudo != null) 'pseudo': pseudo,
      if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      'is_pro': isPro,
      if (proTier != null) 'pro_tier': proTier,
      if (proExpiresAt != null) 'pro_expires_at': proExpiresAt!.toIso8601String(),
    };
  }

  AuthUser copyWith({
    String? name,
    String? pseudo,
    String? avatarEmoji,
    String? country,
    String? city,
    bool? isPro,
    String? proTier,
  }) {
    return AuthUser(
      userId: userId,
      authProvider: authProvider,
      name: name ?? this.name,
      email: email,
      picture: picture,
      pseudo: pseudo ?? this.pseudo,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      dateOfBirth: dateOfBirth,
      country: country ?? this.country,
      city: city ?? this.city,
      isPro: isPro ?? this.isPro,
      proTier: proTier ?? this.proTier,
      proExpiresAt: proExpiresAt,
    );
  }

  String get displayName => pseudo ?? name;

  String get avatarDisplay => avatarEmoji ?? '🦜';
}
