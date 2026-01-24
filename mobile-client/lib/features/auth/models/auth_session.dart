class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.coins,
    required this.soulCount,
    this.isSubscriber = false,
  });

  final String id;
  final String name;
  final String? email;
  final int coins;
  final int soulCount;
  final bool isSubscriber;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      coins: (json['coins'] as num).toInt(),
      soulCount: (json['soulCount'] as num).toInt(),
      isSubscriber: (json['isSubscriber'] as bool?) ?? false,
    );
  }

  AuthUser copyWith({
    String? name,
    String? email,
    int? coins,
    int? soulCount,
    bool? isSubscriber,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      coins: coins ?? this.coins,
      soulCount: soulCount ?? this.soulCount,
      isSubscriber: isSubscriber ?? this.isSubscriber,
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
