import 'experience_entry.dart';

class QuestResult {
  final ExperienceEntry entry;
  final bool didLevelUp;
  final int newLevel;
  final String? newTitle;

  const QuestResult({
    required this.entry,
    required this.didLevelUp,
    required this.newLevel,
    this.newTitle,
  });
}
