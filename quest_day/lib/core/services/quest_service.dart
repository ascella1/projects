import 'dart:math';
import '../models/quest.dart';
import '../models/user_profile.dart';
import 'quest_database.dart';

class QuestService {
  // 하루 3개의 다양한 퀘스트를 추천
  static List<Quest> recommendMultiple({
    required UserProfile profile,
    required List<String> recentlyCompletedIds,
    required int count,
    List<String> excludeIds = const [],
  }) {
    final candidates = _filterCandidates(
      profile: profile,
      recentlyCompletedIds: recentlyCompletedIds,
      excludeIds: excludeIds,
    );

    if (candidates.isEmpty) {
      final fallback = QuestDatabase.all
          .where((q) => q.comfortLevel.index <= profile.comfortZone.index)
          .toList()
        ..shuffle();
      return fallback.take(count).toList();
    }

    final results = <Quest>[];
    final usedIds = <String>{};

    // 1차: 카테고리 다양성 보장 - 카테고리별로 1개씩 먼저 선택
    final categoryOrder = _diverseCategoryOrder(candidates, profile, recentlyCompletedIds);
    for (final cat in categoryOrder) {
      if (results.length >= count) break;
      final catCandidates = candidates
          .where((q) => q.category == cat && !usedIds.contains(q.id))
          .toList();
      if (catCandidates.isEmpty) continue;
      final weights = catCandidates
          .map((q) => _score(q, profile, recentlyCompletedIds))
          .toList();
      final picked = _weightedRandom(catCandidates, weights);
      results.add(picked);
      usedIds.add(picked.id);
    }

    // 2차: 부족한 슬롯 채우기
    while (results.length < count) {
      final remaining =
          candidates.where((q) => !usedIds.contains(q.id)).toList();
      if (remaining.isEmpty) break;
      final weights =
          remaining.map((q) => _score(q, profile, recentlyCompletedIds)).toList();
      final picked = _weightedRandom(remaining, weights);
      results.add(picked);
      usedIds.add(picked.id);
    }

    return results;
  }

  // 카테고리를 최근 빈도 역순으로 정렬 (덜 나온 카테고리 우선)
  static List<QuestCategory> _diverseCategoryOrder(
    List<Quest> candidates,
    UserProfile profile,
    List<String> recentlyCompleted,
  ) {
    final recentCats = _recentCategories(recentlyCompleted);
    final availableCats = candidates.map((q) => q.category).toSet().toList();
    availableCats.sort((a, b) =>
        (recentCats[a] ?? 0).compareTo(recentCats[b] ?? 0));
    return availableCats;
  }

  static List<Quest> _filterCandidates({
    required UserProfile profile,
    required List<String> recentlyCompletedIds,
    List<String> excludeIds = const [],
  }) {
    return QuestDatabase.all.where((q) {
      if (excludeIds.contains(q.id)) return false;
      if (q.comfortLevel.index > profile.comfortZone.index) return false;
      if (recentlyCompletedIds.contains(q.id)) return false;
      return true;
    }).toList();
  }

  static double _score(
    Quest q,
    UserProfile profile,
    List<String> recentlyCompleted,
  ) {
    double score = 1.0;

    final recentCats = _recentCategories(recentlyCompleted);
    final catCount = recentCats[q.category] ?? 0;
    score *= max(0.2, 1.0 - catCount * 0.2);

    switch (q.category) {
      case QuestCategory.social:
        score *= 0.5 + (profile.personality['social'] ?? 0.5);
      case QuestCategory.exploration:
        score *= 0.5 + (profile.personality['exploration'] ?? 0.5);
      case QuestCategory.creative:
        score *= 0.5 + (profile.personality['creativity'] ?? 0.5);
      case QuestCategory.action:
        score *= 0.5 + (profile.personality['activity'] ?? 0.5);
      case QuestCategory.thinking:
        score *= 0.7;
      case QuestCategory.relationship:
        score *= 0.6 + (profile.personality['social'] ?? 0.5) * 0.4;
      case QuestCategory.random:
        score *= 0.5 + (profile.personality['spontaneity'] ?? 0.5) * 0.5;
    }

    final targetDiff = (profile.level / 5.0).clamp(1.0, 4.0);
    score *= max(0.3, 1.0 - (q.difficulty - targetDiff).abs() * 0.15);

    return score;
  }

  static Map<QuestCategory, int> _recentCategories(List<String> ids) {
    final map = <QuestCategory, int>{};
    for (final id in ids.take(7)) {
      final q = QuestDatabase.findById(id);
      if (q != null) {
        map[q.category] = (map[q.category] ?? 0) + 1;
      }
    }
    return map;
  }

  static Quest _weightedRandom(List<Quest> quests, List<double> weights) {
    final totalWeight = weights.fold(0.0, (a, b) => a + b);
    final rand = Random().nextDouble() * totalWeight;
    double cumulative = 0;
    for (int i = 0; i < quests.length; i++) {
      cumulative += weights[i];
      if (rand <= cumulative) return quests[i];
    }
    return quests.last;
  }

  static int computeXP(Quest quest) => quest.baseXP;

  static Map<String, int> computeStatBoosts(Quest quest) {
    return {for (final b in quest.statBoosts) b.stat: b.value};
  }
}
