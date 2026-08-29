enum QuestCategory {
  exploration,
  social,
  creative,
  thinking,
  action,
  relationship,
  random,
}

enum ComfortLevel { safe, normal, challenge, crazy }

class StatBoost {
  final String stat;
  final int value;
  const StatBoost(this.stat, this.value);
}

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestCategory category;
  final int difficulty;
  final int baseXP;
  final ComfortLevel comfortLevel;
  final List<StatBoost> statBoosts;
  final String emoji;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.baseXP,
    required this.comfortLevel,
    required this.statBoosts,
    required this.emoji,
  });

  String get difficultyStars => '★' * difficulty + '☆' * (5 - difficulty);

  String get categoryName {
    switch (category) {
      case QuestCategory.exploration:
        return 'EXPLORATION';
      case QuestCategory.social:
        return 'SOCIAL';
      case QuestCategory.creative:
        return 'CREATIVE';
      case QuestCategory.thinking:
        return 'THINKING';
      case QuestCategory.action:
        return 'ACTION';
      case QuestCategory.relationship:
        return 'RELATIONSHIP';
      case QuestCategory.random:
        return 'RANDOM';
    }
  }

  String get comfortLevelName {
    switch (comfortLevel) {
      case ComfortLevel.safe:
        return 'SAFE';
      case ComfortLevel.normal:
        return 'NORMAL';
      case ComfortLevel.challenge:
        return 'CHALLENGE';
      case ComfortLevel.crazy:
        return 'CRAZY';
    }
  }
}
