import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/quest_entity.dart';
import '../../domain/repositories/quest_repository.dart';

class QuestRepositoryImpl implements QuestRepository {
  static const String sharedPrefKey = 'noai_rpg_quests_v1';

  List<Quest> _cache = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(sharedPrefKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _cache = list
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    _loaded = true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        sharedPrefKey,
        jsonEncode(_cache.map((q) => q.toJson()).toList()),
      );
    } catch (_) {}
  }

  @override
  Future<List<Quest>> getQuests(String goalId) async {
    await _ensureLoaded();
    return _cache.where((q) => q.goalId == goalId).toList();
  }

  @override
  Future<void> createQuests(List<Quest> quests) async {
    await _ensureLoaded();
    if (quests.isNotEmpty) {
      final targetGoalId = quests.first.goalId;
      _cache.removeWhere((q) => q.goalId == targetGoalId);
    }
    _cache.addAll(quests);
    await _persist();
  }

  @override
  Future<void> completeQuest(String questId) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _cache[index] = _cache[index].copyWith(
        status: QuestStatus.completed,
        completedAt: DateTime.now(),
      );
      await _persist();
    }
  }

  @override
  Future<void> failQuest(String questId) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _cache[index] = _cache[index].copyWith(status: QuestStatus.failed);
      await _persist();
    }
  }

  @override
  Future<void> updateQuestDifficulty(
      String questId, QuestDifficulty newDifficulty) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _cache[index] = _cache[index].copyWith(difficulty: newDifficulty);
      await _persist();
    }
  }
}
