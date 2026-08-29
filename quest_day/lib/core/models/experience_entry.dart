import 'dart:convert';

class ExperienceEntry {
  final String id;
  final String questId;
  final String title;
  final String description;
  final String emoji;
  final int number;
  final int xpEarned;
  final Map<String, int> statBoosts;
  final String completedAt;
  final String category;

  const ExperienceEntry({
    required this.id,
    required this.questId,
    required this.title,
    required this.description,
    required this.emoji,
    required this.number,
    required this.xpEarned,
    required this.statBoosts,
    required this.completedAt,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'questId': questId,
        'title': title,
        'description': description,
        'emoji': emoji,
        'number': number,
        'xpEarned': xpEarned,
        'statBoosts': statBoosts,
        'completedAt': completedAt,
        'category': category,
      };

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) =>
      ExperienceEntry(
        id: json['id'] as String,
        questId: json['questId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        emoji: json['emoji'] as String,
        number: json['number'] as int,
        xpEarned: json['xpEarned'] as int,
        statBoosts: Map<String, int>.from(
          (json['statBoosts'] as Map).map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ),
        ),
        completedAt: json['completedAt'] as String,
        category: json['category'] as String,
      );

  static List<ExperienceEntry> listFromJson(String s) {
    final list = jsonDecode(s) as List;
    return list
        .map((e) => ExperienceEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<ExperienceEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());
}
