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

class SpecialClaimResult {
  final int xpEarned;
  final bool didLevelUp;
  final int newLevel;
  final String? newTitle;

  const SpecialClaimResult({
    required this.xpEarned,
    required this.didLevelUp,
    required this.newLevel,
    this.newTitle,
  });
}
