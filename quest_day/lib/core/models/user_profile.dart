import 'dart:convert';
import 'dart:math';
import 'quest.dart';

class UserProfile {
  final String nickname;
  final Map<String, double> personality;
  final ComfortLevel comfortZone;
  final int level;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final String? lastQuestDate;
  final List<String> completedQuestIds;

  const UserProfile({
    required this.nickname,
    required this.personality,
    required this.comfortZone,
    this.level = 1,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastQuestDate,
    this.completedQuestIds = const [],
  });

  // ── XP 공식 ─────────────────────────────────────────────────────────────────
  // level n → (n+1) 레벨 진입에 필요한 XP: 80 * n^1.9
  // 초반(1-5레벨): 매우 빠름, 후반(30레벨+): 매우 느림
  //
  //  L1→2:   80 XP  (~퀘스트 1개)
  //  L2→3:  299 XP  (~퀘스트 3-4개)
  //  L3→4:  645 XP  (~이틀)
  //  L5→6:  1689 XP (~6일)
  //  L10→11: 6209 XP (~20일)
  //  L20→21: 22352 XP (~75일)
  //  L30→31: 46197 XP (~154일)

  static int levelRequirement(int level) => (80 * pow(level, 1.9)).floor();

  static int cumulativeXp(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += levelRequirement(i);
    }
    return total;
  }

  static int computeLevel(int totalXP) {
    int level = 1;
    while (totalXP >= cumulativeXp(level + 1)) {
      level++;
      if (level >= 100) break;
    }
    return level;
  }

  int get xpForNextLevel => levelRequirement(level);
  int get xpInCurrentLevel => totalXP - cumulativeXp(level);
  double get levelProgress =>
      (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);

  UserProfile copyWith({
    String? nickname,
    Map<String, double>? personality,
    ComfortLevel? comfortZone,
    int? level,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    String? lastQuestDate,
    List<String>? completedQuestIds,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      personality: personality ?? this.personality,
      comfortZone: comfortZone ?? this.comfortZone,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastQuestDate: lastQuestDate ?? this.lastQuestDate,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'personality': personality,
        'comfortZone': comfortZone.index,
        'level': level,
        'totalXP': totalXP,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastQuestDate': lastQuestDate,
        'completedQuestIds': completedQuestIds,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        nickname: json['nickname'] as String,
        personality: Map<String, double>.from(
          (json['personality'] as Map).map(
            (k, v) => MapEntry(k as String, (v as num).toDouble()),
          ),
        ),
        comfortZone: ComfortLevel.values[json['comfortZone'] as int],
        level: json['level'] as int? ?? 1,
        totalXP: json['totalXP'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastQuestDate: json['lastQuestDate'] as String?,
        completedQuestIds:
            List<String>.from(json['completedQuestIds'] as List? ?? []),
      );

  String toJsonString() => jsonEncode(toJson());

  factory UserProfile.fromJsonString(String s) =>
      UserProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
