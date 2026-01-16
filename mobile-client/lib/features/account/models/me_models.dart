class MeStats {
  const MeStats({
    required this.totalWins,
    required this.totalLosses,
    required this.totalDraws,
    required this.currentStreak,
    required this.maxStreak,
  });

  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final int currentStreak;
  final int maxStreak;

  factory MeStats.fromJson(Map<String, dynamic> json) {
    return MeStats(
      totalWins: (json['totalWins'] as num).toInt(),
      totalLosses: (json['totalLosses'] as num).toInt(),
      totalDraws: (json['totalDraws'] as num).toInt(),
      currentStreak: (json['currentStreak'] as num).toInt(),
      maxStreak: (json['maxStreak'] as num).toInt(),
    );
  }
}

class MeUser {
  const MeUser({
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
    required this.isSubscriber,
    required this.isRatingPublic,
    required this.isWinCountPublic,
    required this.isWinRatePublic,
    required this.isStreakPublic,
    required this.stats,
    required this.lastRatingDelta,
    required this.lastMatchAt,
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

  final MeStats? stats;

  final int? lastRatingDelta;
  final DateTime? lastMatchAt;

  factory MeUser.fromJson(Map<String, dynamic> json) {
    return MeUser(
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
      isSubscriber: json['isSubscriber'] as bool,
      isRatingPublic: json['isRatingPublic'] as bool,
      isWinCountPublic: json['isWinCountPublic'] as bool,
      isWinRatePublic: json['isWinRatePublic'] as bool,
      isStreakPublic: json['isStreakPublic'] as bool,
      stats: json['stats'] == null
          ? null
          : MeStats.fromJson(json['stats'] as Map<String, dynamic>),
      lastRatingDelta: (json['lastRatingDelta'] as num?)?.toInt(),
      lastMatchAt: json['lastMatchAt'] == null
          ? null
          : DateTime.parse(json['lastMatchAt'] as String),
    );
  }
}

class InventoryMessage {
  const InventoryMessage({
    required this.id,
    required this.content,
    required this.rarity,
  });

  final String id;
  final String content;
  final int rarity;

  factory InventoryMessage.fromJson(Map<String, dynamic> json) {
    return InventoryMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      rarity: (json['rarity'] as num).toInt(),
    );
  }
}

class InventoryEquipped {
  const InventoryEquipped({
    required this.iconId,
    required this.messageId,
    required this.title1Id,
    required this.title2Id,
    required this.title3Id,
  });

  final String iconId;
  final String messageId;
  final String? title1Id;
  final String? title2Id;
  final String? title3Id;

  factory InventoryEquipped.fromJson(Map<String, dynamic> json) {
    return InventoryEquipped(
      iconId: json['iconId'] as String,
      messageId: json['messageId'] as String,
      title1Id: json['title1Id'] as String?,
      title2Id: json['title2Id'] as String?,
      title3Id: json['title3Id'] as String?,
    );
  }
}

class InventoryIcon {
  const InventoryIcon({
    required this.id,
    required this.imageUrl,
    required this.rarity,
  });

  final String id;
  final String imageUrl;
  final int rarity;

  factory InventoryIcon.fromJson(Map<String, dynamic> json) {
    return InventoryIcon(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      rarity: (json['rarity'] as num).toInt(),
    );
  }
}

class InventoryTitle {
  const InventoryTitle({
    required this.id,
    required this.name,
    required this.description,
    required this.condition,
    required this.rarity,
  });

  final String id;
  final String name;
  final String description;
  final String condition;
  final int rarity;

  factory InventoryTitle.fromJson(Map<String, dynamic> json) {
    return InventoryTitle(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      condition: json['condition'] as String,
      rarity: (json['rarity'] as num).toInt(),
    );
  }
}

class InventoryResponse {
  const InventoryResponse({
    required this.equipped,
    required this.icons,
    required this.messages,
    required this.titles,
  });

  final InventoryEquipped equipped;
  final List<InventoryIcon> icons;
  final List<InventoryMessage> messages;
  final List<InventoryTitle> titles;

  factory InventoryResponse.fromJson(Map<String, dynamic> json) {
    return InventoryResponse(
      equipped: InventoryEquipped.fromJson(
        json['equipped'] as Map<String, dynamic>,
      ),
      icons: (json['icons'] as List<dynamic>)
          .map((x) => InventoryIcon.fromJson(x as Map<String, dynamic>))
          .toList(growable: false),
        messages: (json['messages'] as List<dynamic>)
          .map((x) => InventoryMessage.fromJson(x as Map<String, dynamic>))
          .toList(growable: false),
      titles: (json['titles'] as List<dynamic>)
          .map((x) => InventoryTitle.fromJson(x as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
