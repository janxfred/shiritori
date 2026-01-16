class MatchmakeOpponent {
  MatchmakeOpponent({
    required this.userId,
    required this.name,
    required this.iconImageUrl,
    required this.messageContent,
    required this.titleName,
    required this.rating,
    required this.totalWins,
    required this.winRate,
    required this.maxStreak,
  });

  final String userId;
  final String name;
  final String iconImageUrl;
  final String messageContent;
  final String? titleName;

  final int? rating;
  final int? totalWins;
  final double? winRate;
  final int? maxStreak;

  factory MatchmakeOpponent.fromJson(Map<String, dynamic> json) {
    final icon = json['icon'] as Map<String, dynamic>;
    final message = json['message'] as Map<String, dynamic>;
    final title = json['title'] as Map<String, dynamic>?;

    return MatchmakeOpponent(
      userId: json['userId'] as String,
      name: json['name'] as String,
      iconImageUrl: icon['imageUrl'] as String,
      messageContent: message['content'] as String,
      titleName: title == null ? null : title['name'] as String,
      rating: (json['rating'] as num?)?.toInt(),
      totalWins: (json['totalWins'] as num?)?.toInt(),
      winRate: (json['winRate'] as num?)?.toDouble(),
      maxStreak: (json['maxStreak'] as num?)?.toInt(),
    );
  }
}

class MatchmakeResponse {
  MatchmakeResponse({required this.sessionId, required this.opponent});

  final String sessionId;
  final MatchmakeOpponent opponent;

  factory MatchmakeResponse.fromJson(Map<String, dynamic> json) {
    return MatchmakeResponse(
      sessionId: (json['session'] as Map<String, dynamic>)['id'] as String,
      opponent: MatchmakeOpponent.fromJson(
        json['opponent'] as Map<String, dynamic>,
      ),
    );
  }
}

typedef MatchResult = String; // 'win' | 'loss' | 'draw'

class CreateMatchResponse {
  CreateMatchResponse({
    required this.message,
    required this.ratingDelta,
    required this.updatedRating,
  });

  final String message;
  final int ratingDelta;
  final int updatedRating;

  factory CreateMatchResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return CreateMatchResponse(
      message: json['message'] as String,
      ratingDelta: (json['ratingDelta'] as num).toInt(),
      updatedRating: (user['rating'] as num).toInt(),
    );
  }
}
