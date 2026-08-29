import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../features/quest/domain/entities/quest_entity.dart';

// assets/data/mokpyo_templates.json 에 정의된 "흔한 목표" 템플릿.
// 목표 문자열이 어떤 카테고리의 keywords와 하나라도 겹치면 AI 호출 없이
// 해당 카테고리의 퀘스트를 그대로 사용한다. 매칭되는 카테고리가 없으면 null을 반환해
// 호출부가 AI 생성으로 넘어가게 한다.
class TemplateMatch {
  final List<String> stats;
  final List<Quest> quests;

  const TemplateMatch({required this.stats, required this.quests});
}

class TemplateService {
  static const _assetPath = 'assets/data/mokpyo_templates.json';

  static List<Map<String, dynamic>>? _categoriesCache;

  static Future<List<Map<String, dynamic>>> _loadCategories() async {
    if (_categoriesCache != null) return _categoriesCache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final categories = (decoded['categories'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    _categoriesCache = categories;
    return categories;
  }

  // goal에 매칭되는 첫 번째 카테고리를 찾아 Quest 목록을 생성한다.
  // 매칭되는 카테고리가 없으면 null을 반환한다.
  static Future<TemplateMatch?> matchGoal(String goal, String goalId) async {
    final categories = await _loadCategories();
    final normalized = goal.toLowerCase();

    for (final category in categories) {
      final keywords = (category['keywords'] as List<dynamic>).cast<String>();
      final matched = keywords.any((k) => normalized.contains(k.toLowerCase()));
      if (!matched) continue;

      final stats = (category['stats'] as List<dynamic>).cast<String>();
      final questsJson = (category['quests'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      int index = 0;
      final quests = questsJson.map((q) {
        final title =
            (q['title'] as String).replaceAll('{goal}', goal);
        final depth = q['depth'] as int;
        final diffStr = q['difficulty'] as String;
        final rewardExp = q['rewardExp'] as int;
        final dueDays = q['dueDays'] as int;

        QuestDifficulty diff = QuestDifficulty.easy;
        if (diffStr == 'medium') diff = QuestDifficulty.medium;
        if (diffStr == 'hard') diff = QuestDifficulty.hard;

        return Quest(
          id: 'q_${goalId}_${index++}',
          goalId: goalId,
          title: title,
          depth: depth,
          status: QuestStatus.todo,
          difficulty: diff,
          rewardExp: rewardExp,
          rewardStats: stats,
          dueDate: DateTime.now().add(Duration(days: dueDays)),
        );
      }).toList();

      return TemplateMatch(stats: stats, quests: quests);
    }

    return null;
  }
}
