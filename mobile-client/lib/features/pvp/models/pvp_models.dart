class PvpTurnHistoryEntry {
  const PvpTurnHistoryEntry({
    required this.turn,
    required this.playerId,
    required this.word,
    required this.isValid,
    required this.capturedChars,
    required this.message,
  });

  final int turn;
  final String playerId;
  final String word;
  final bool isValid;
  final List<String> capturedChars;
  final String message;

  factory PvpTurnHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PvpTurnHistoryEntry(
      turn: (json['turn'] as num).toInt(),
      playerId: json['playerId'] as String,
      word: json['word'] as String,
      isValid: json['isValid'] as bool,
      capturedChars: (json['capturedChars'] as List<dynamic>).cast<String>(),
      message: json['message'] as String,
    );
  }
}

typedef PvpSessionStatus = String; // 'playing' | 'p1_win' | 'p2_win' | 'draw'

class PvpSession {
  const PvpSession({
    required this.id,
    required this.status,
    required this.player1Id,
    required this.player2Id,
    required this.currentTurnUserId,
    required this.player1MistakeCount,
    required this.player2MistakeCount,
    required this.player1CapturedChars,
    required this.player2CapturedChars,
    required this.lastWord,
    required this.expectedStartChar,
    required this.turnCount,
    required this.roundCount,
    required this.maxRounds,
    required this.history,
    required this.turnStartedAt,
    required this.remainingTimeMs,
  });

  final String id;
  final PvpSessionStatus status;

  final String player1Id;
  final String player2Id;
  final String currentTurnUserId;

  final int player1MistakeCount;
  final int player2MistakeCount;

  final List<String> player1CapturedChars;
  final List<String> player2CapturedChars;

  final String? lastWord;
  final String expectedStartChar;

  final int turnCount;
  final int roundCount;
  final int maxRounds;

  final List<PvpTurnHistoryEntry> history;

  final String turnStartedAt;
  final int remainingTimeMs;

  factory PvpSession.fromJson(Map<String, dynamic> json) {
    return PvpSession(
      id: json['id'] as String,
      status: json['status'] as String,
      player1Id: json['player1Id'] as String,
      player2Id: json['player2Id'] as String,
      currentTurnUserId: json['currentTurnUserId'] as String,
      player1MistakeCount: (json['player1MistakeCount'] as num).toInt(),
      player2MistakeCount: (json['player2MistakeCount'] as num).toInt(),
      player1CapturedChars:
          (json['player1CapturedChars'] as List<dynamic>).cast<String>(),
      player2CapturedChars:
          (json['player2CapturedChars'] as List<dynamic>).cast<String>(),
      lastWord: json['lastWord'] as String?,
      expectedStartChar: json['expectedStartChar'] as String,
      turnCount: (json['turnCount'] as num).toInt(),
      roundCount: (json['roundCount'] as num).toInt(),
      maxRounds: (json['maxRounds'] as num).toInt(),
      history: (json['history'] as List<dynamic>)
          .map((e) => PvpTurnHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      turnStartedAt: json['turnStartedAt'] as String,
      remainingTimeMs: (json['remainingTimeMs'] as num).toInt(),
    );
  }
}

class PvpOpponent {
  const PvpOpponent({
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

  factory PvpOpponent.fromJson(Map<String, dynamic> json) {
    final icon = json['icon'] as Map<String, dynamic>;
    final message = json['message'] as Map<String, dynamic>;
    final title = json['title'] as Map<String, dynamic>?;

    return PvpOpponent(
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

class PvpStartResponse {
  const PvpStartResponse({required this.session, required this.opponent});

  final PvpSession session;
  final PvpOpponent opponent;

  factory PvpStartResponse.fromJson(Map<String, dynamic> json) {
    return PvpStartResponse(
      session: PvpSession.fromJson(json['session'] as Map<String, dynamic>),
      opponent: PvpOpponent.fromJson(json['opponent'] as Map<String, dynamic>),
    );
  }
}

class PvpPlayerResult {
  const PvpPlayerResult({
    required this.word,
    required this.isValid,
    required this.message,
    required this.capturedChars,
    required this.timeExpired,
  });

  final String word;
  final bool isValid;
  final String message;
  final List<String> capturedChars;
  final bool timeExpired;

  factory PvpPlayerResult.fromJson(Map<String, dynamic> json) {
    return PvpPlayerResult(
      word: json['word'] as String,
      isValid: json['isValid'] as bool,
      message: json['message'] as String,
      capturedChars: (json['capturedChars'] as List<dynamic>).cast<String>(),
      timeExpired: (json['timeExpired'] as bool?) ?? false,
    );
  }
}

class PvpRated {
  const PvpRated({
    required this.userId,
    required this.opponentId,
    required this.userRating,
    required this.opponentRating,
    required this.userDelta,
    required this.opponentDelta,
  });

  final String userId;
  final String opponentId;
  final int userRating;
  final int opponentRating;
  final int userDelta;
  final int opponentDelta;

  factory PvpRated.fromJson(Map<String, dynamic> json) {
    return PvpRated(
      userId: json['userId'] as String,
      opponentId: json['opponentId'] as String,
      userRating: (json['userRating'] as num).toInt(),
      opponentRating: (json['opponentRating'] as num).toInt(),
      userDelta: (json['userDelta'] as num).toInt(),
      opponentDelta: (json['opponentDelta'] as num).toInt(),
    );
  }
}

class PvpSubmitResponse {
  const PvpSubmitResponse({
    required this.session,
    required this.playerResult,
    required this.gameOver,
    required this.winnerUserId,
    required this.rated,
  });

  final PvpSession session;
  final PvpPlayerResult playerResult;
  final bool gameOver;
  final String? winnerUserId;
  final PvpRated? rated;

  factory PvpSubmitResponse.fromJson(Map<String, dynamic> json) {
    return PvpSubmitResponse(
      session: PvpSession.fromJson(json['session'] as Map<String, dynamic>),
      playerResult:
          PvpPlayerResult.fromJson(json['playerResult'] as Map<String, dynamic>),
      gameOver: json['gameOver'] as bool,
      winnerUserId: json['winnerUserId'] as String?,
      rated: json['rated'] == null
          ? null
          : PvpRated.fromJson(json['rated'] as Map<String, dynamic>),
    );
  }
}

class PvpCheckTimeResponse {
  const PvpCheckTimeResponse({
    required this.expired,
    required this.session,
    required this.message,
  });

  final bool expired;
  final PvpSession? session;
  final String? message;

  factory PvpCheckTimeResponse.fromJson(Map<String, dynamic> json) {
    return PvpCheckTimeResponse(
      expired: json['expired'] as bool,
      session: json['session'] == null
          ? null
          : PvpSession.fromJson(json['session'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );
  }
}
