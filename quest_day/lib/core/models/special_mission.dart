class SpecialMission {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int bonusXp;

  const SpecialMission({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.bonusXp,
  });

  factory SpecialMission.fromJson(Map<String, dynamic> j) => SpecialMission(
        id: j['id'] as String,
        emoji: j['emoji'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        bonusXp: j['bonusXp'] as int,
      );
}

class SpecialMissionClaim {
  final String claimerNickname;
  final String claimerDeviceId;
  final DateTime claimedAt;

  const SpecialMissionClaim({
    required this.claimerNickname,
    required this.claimerDeviceId,
    required this.claimedAt,
  });

  factory SpecialMissionClaim.fromJson(Map<String, dynamic> j) =>
      SpecialMissionClaim(
        claimerNickname: j['claimer_nickname'] as String,
        claimerDeviceId: j['claimer_device_id'] as String,
        claimedAt: DateTime.parse(j['claimed_at'] as String).toLocal(),
      );

  bool isMe(String deviceId) => claimerDeviceId == deviceId;
}

class SpecialClaimResult {
  final bool isWinner;
  final SpecialMissionClaim winner;
  final int xpEarned;
  final bool didLevelUp;
  final int newLevel;
  final String? newTitle;

  const SpecialClaimResult({
    required this.isWinner,
    required this.winner,
    required this.xpEarned,
    required this.didLevelUp,
    required this.newLevel,
    this.newTitle,
  });
}
