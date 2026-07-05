import '../entities/quest_entity.dart';

abstract class QuestRepository {
  Future<List<Quest>> getQuests(String goalId);
  Future<void> createQuests(List<Quest> quests);
  Future<void> completeQuest(String questId);
  Future<void> failQuest(String questId);
  Future<void> updateQuestDifficulty(String questId, QuestDifficulty newDifficulty);
}
