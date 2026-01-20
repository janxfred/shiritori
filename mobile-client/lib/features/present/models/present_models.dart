class PresentItem {
  const PresentItem({
    required this.id,
    required this.type,
    required this.targetId,
    required this.amount,
    required this.description,
    required this.claimed,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String type; // "coin" | "title" | "message" | "icon" | "item"
  final String? targetId;
  final int amount;
  final String description;
  final bool claimed;
  final String createdAt;
  final String? expiresAt;

  factory PresentItem.fromJson(Map<String, dynamic> json) {
    return PresentItem(
      id: json['id'] as String,
      type: json['type'] as String,
      targetId: json['targetId'] as String?,
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String,
      claimed: json['claimed'] as bool,
      createdAt: json['createdAt'] as String,
      expiresAt: json['expiresAt'] as String?,
    );
  }
}

class PresentListResponse {
  const PresentListResponse({
    required this.presents,
    required this.unclaimedCount,
  });

  final List<PresentItem> presents;
  final int unclaimedCount;

  factory PresentListResponse.fromJson(Map<String, dynamic> json) {
    final presentsJson = json['presents'];
    final presents = (presentsJson is List)
        ? presentsJson
            .whereType<Map<String, dynamic>>()
            .map(PresentItem.fromJson)
            .toList(growable: false)
        : const <PresentItem>[];

    return PresentListResponse(
      presents: presents,
      unclaimedCount: (json['unclaimedCount'] as num).toInt(),
    );
  }
}

class ClaimReward {
  const ClaimReward({
    required this.type,
    required this.targetId,
    required this.amount,
    required this.description,
  });

  final String type;
  final String? targetId;
  final int amount;
  final String description;

  factory ClaimReward.fromJson(Map<String, dynamic> json) {
    return ClaimReward(
      type: json['type'] as String,
      targetId: json['targetId'] as String?,
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String,
    );
  }
}

class ClaimPresentResponse {
  const ClaimPresentResponse({
    required this.message,
    required this.reward,
  });

  final String message;
  final ClaimReward reward;

  factory ClaimPresentResponse.fromJson(Map<String, dynamic> json) {
    return ClaimPresentResponse(
      message: json['message'] as String,
      reward: ClaimReward.fromJson(json['reward'] as Map<String, dynamic>),
    );
  }
}

class ClaimAllPresentsResponse {
  const ClaimAllPresentsResponse({
    required this.message,
    required this.claimedCount,
    required this.rewards,
  });

  final String message;
  final int claimedCount;
  final List<ClaimReward> rewards;

  factory ClaimAllPresentsResponse.fromJson(Map<String, dynamic> json) {
    final rewardsJson = json['rewards'];
    final rewards = (rewardsJson is List)
        ? rewardsJson
            .whereType<Map<String, dynamic>>()
            .map(ClaimReward.fromJson)
            .toList(growable: false)
        : const <ClaimReward>[];

    return ClaimAllPresentsResponse(
      message: json['message'] as String,
      claimedCount: (json['claimedCount'] as num).toInt(),
      rewards: rewards,
    );
  }
}
