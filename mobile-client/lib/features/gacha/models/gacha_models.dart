sealed class GachaReward {
  const GachaReward();

  factory GachaReward.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'icon':
        return GachaIconReward.fromJson(json);
      case 'message':
        return GachaMessageReward.fromJson(json);
      case 'title':
        return GachaTitleReward.fromJson(json);
      case 'item':
        return GachaItemReward.fromJson(json);
      default:
        throw StateError('未知のreward.type: $type');
    }
  }

  String get type;
}

class GachaStatusResponse {
  const GachaStatusResponse({
    required this.cost,
    required this.coins,
  });

  final int cost;
  final int coins;

  factory GachaStatusResponse.fromJson(Map<String, dynamic> json) {
    return GachaStatusResponse(
      cost: (json['cost'] as num).toInt(),
      coins: (json['coins'] as num).toInt(),
    );
  }
}

class GachaDrawResponse {
  const GachaDrawResponse({
    required this.message,
    required this.coins,
    required this.reward,
  });

  final String message;
  final int coins;
  final GachaReward reward;

  factory GachaDrawResponse.fromJson(Map<String, dynamic> json) {
    return GachaDrawResponse(
      message: json['message'] as String,
      coins: (json['coins'] as num).toInt(),
      reward: GachaReward.fromJson(json['reward'] as Map<String, dynamic>),
    );
  }
}

class GachaIconReward extends GachaReward {
  const GachaIconReward({
    required this.id,
    required this.imageUrl,
    required this.rarity,
  });

  final String id;
  final String imageUrl;
  final String rarity;

  factory GachaIconReward.fromJson(Map<String, dynamic> json) {
    return GachaIconReward(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      rarity: json['rarity'] as String,
    );
  }

  @override
  String get type => 'icon';
}

class GachaMessageReward extends GachaReward {
  const GachaMessageReward({
    required this.id,
    required this.content,
    required this.rarity,
  });

  final String id;
  final String content;
  final String rarity;

  factory GachaMessageReward.fromJson(Map<String, dynamic> json) {
    return GachaMessageReward(
      id: json['id'] as String,
      content: json['content'] as String,
      rarity: json['rarity'] as String,
    );
  }

  @override
  String get type => 'message';
}

class GachaTitleReward extends GachaReward {
  const GachaTitleReward({
    required this.id,
    required this.name,
    required this.description,
    required this.condition,
  });

  final String id;
  final String name;
  final String description;
  final String condition;

  factory GachaTitleReward.fromJson(Map<String, dynamic> json) {
    return GachaTitleReward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      condition: (json['condition'] as String?) ?? '',
    );
  }

  @override
  String get type => 'title';
}

class GachaItemReward extends GachaReward {
  const GachaItemReward({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
  });

  final String id;
  final String name;
  final String description;
  final String rarity;

  factory GachaItemReward.fromJson(Map<String, dynamic> json) {
    return GachaItemReward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      rarity: (json['rarity'] as String?) ?? '',
    );
  }

  @override
  String get type => 'item';
}
