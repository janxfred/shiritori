class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.iconId,
    required this.messageId,
    required this.title1Id,
    required this.title2Id,
    required this.title3Id,
    required this.level,
    required this.exp,
    required this.rating,
    required this.coins,
    required this.soulCount,
    this.isSubscriber = false,
    this.isRatingPublic = true,
    this.isWinCountPublic = true,
    this.isWinRatePublic = true,
    this.isStreakPublic = true,
  });

  final String id;
  final String name;
  final String? email;

  final String iconId;
  final String messageId;
  final String? title1Id;
  final String? title2Id;
  final String? title3Id;

  final int level;
  final int exp;
  final int rating;
  final int coins;
  final int soulCount;
  final bool isSubscriber;

  final bool isRatingPublic;
  final bool isWinCountPublic;
  final bool isWinRatePublic;
  final bool isStreakPublic;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      iconId: json['iconId'] as String,
      messageId: json['messageId'] as String,
      title1Id: json['title1Id'] as String?,
      title2Id: json['title2Id'] as String?,
      title3Id: json['title3Id'] as String?,
      level: (json['level'] as num).toInt(),
      exp: (json['exp'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      coins: (json['coins'] as num).toInt(),
      soulCount: (json['soulCount'] as num).toInt(),
      isSubscriber: (json['isSubscriber'] as bool?) ?? false,
      isRatingPublic: (json['isRatingPublic'] as bool?) ?? true,
      isWinCountPublic: (json['isWinCountPublic'] as bool?) ?? true,
      isWinRatePublic: (json['isWinRatePublic'] as bool?) ?? true,
      isStreakPublic: (json['isStreakPublic'] as bool?) ?? true,
    );
  }

  AuthUser copyWith({
    String? name,
    String? email,
    String? iconId,
    String? messageId,
    String? title1Id,
    String? title2Id,
    String? title3Id,
    int? level,
    int? exp,
    int? rating,
    int? coins,
    int? soulCount,
    bool? isSubscriber,
    bool? isRatingPublic,
    bool? isWinCountPublic,
    bool? isWinRatePublic,
    bool? isStreakPublic,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      iconId: iconId ?? this.iconId,
      messageId: messageId ?? this.messageId,
      title1Id: title1Id ?? this.title1Id,
      title2Id: title2Id ?? this.title2Id,
      title3Id: title3Id ?? this.title3Id,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      rating: rating ?? this.rating,
      coins: coins ?? this.coins,
      soulCount: soulCount ?? this.soulCount,
      isSubscriber: isSubscriber ?? this.isSubscriber,
      isRatingPublic: isRatingPublic ?? this.isRatingPublic,
      isWinCountPublic: isWinCountPublic ?? this.isWinCountPublic,
      isWinRatePublic: isWinRatePublic ?? this.isWinRatePublic,
      isStreakPublic: isStreakPublic ?? this.isStreakPublic,
    );
  }
}

class AuthSession {
  AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AuthUser user;

  AuthSession copyWith({
    String? token,
    AuthUser? user,
  }) {
    return AuthSession(
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }
}
