import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/quest_repository_impl.dart';
import '../../../../core/services/level_config_service.dart';

class UserState {
  final bool hasCompletedOnboarding;
  final String characterType;
  final String goal;
  final List<String> recommendedStats;
  final int level;
  final int exp;
  final int boxesCount;
  final List<String> inventory;
  final String? equippedAccessory;
  final Map<String, int> statLevels;
  final String lastLoginDate;
  final int currentStreak;
  final bool pendingStreakReward;

  const UserState({
    this.hasCompletedOnboarding = false,
    this.characterType = 'fox',
    this.goal = '',
    this.recommendedStats = const [],
    this.level = 1,
    this.exp = 0,
    this.boxesCount = 0,
    this.inventory = const [],
    this.equippedAccessory,
    this.statLevels = const {
      'knowledge': 0,
      'career': 0,
      'health': 0,
      'money': 0,
      'communication': 0,
    },
    this.lastLoginDate = '',
    this.currentStreak = 0,
    this.pendingStreakReward = false,
  });

  UserState copyWith({
    bool? hasCompletedOnboarding,
    String? characterType,
    String? goal,
    List<String>? recommendedStats,
    int? level,
    int? exp,
    int? boxesCount,
    List<String>? inventory,
    String? equippedAccessory,
    bool clearEquipped = false,
    Map<String, int>? statLevels,
    String? lastLoginDate,
    int? currentStreak,
    bool? pendingStreakReward,
  }) {
    return UserState(
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      characterType: characterType ?? this.characterType,
      goal: goal ?? this.goal,
      recommendedStats: recommendedStats ?? this.recommendedStats,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      boxesCount: boxesCount ?? this.boxesCount,
      inventory: inventory ?? this.inventory,
      equippedAccessory:
          clearEquipped ? null : (equippedAccessory ?? this.equippedAccessory),
      statLevels: statLevels ?? this.statLevels,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      currentStreak: currentStreak ?? this.currentStreak,
      pendingStreakReward: pendingStreakReward ?? this.pendingStreakReward,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'characterType': characterType,
        'goal': goal,
        'recommendedStats': recommendedStats,
        'level': level,
        'exp': exp,
        'boxesCount': boxesCount,
        'inventory': inventory,
        'equippedAccessory': equippedAccessory,
        'statLevels': statLevels,
        'lastLoginDate': lastLoginDate,
        'currentStreak': currentStreak,
        // pendingStreakReward는 앱 시작 시 재계산하므로 저장하지 않음
      };

  factory UserState.fromJson(Map<String, dynamic> map) => UserState(
        hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? false,
        characterType: map['characterType'] ?? 'fox',
        goal: map['goal'] ?? '',
        recommendedStats: List<String>.from(map['recommendedStats'] ?? []),
        level: map['level'] ?? 1,
        exp: map['exp'] ?? 0,
        boxesCount: map['boxesCount'] ?? 0,
        inventory: List<String>.from(map['inventory'] ?? []),
        equippedAccessory: map['equippedAccessory'],
        statLevels: map['statLevels'] != null
            ? Map<String, int>.from(map['statLevels'] as Map)
            : const {
                'knowledge': 0,
                'career': 0,
                'health': 0,
                'money': 0,
                'communication': 0,
              },
        lastLoginDate: map['lastLoginDate'] ?? '',
        currentStreak: map['currentStreak'] ?? 0,
        pendingStreakReward: false,
      );
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(const UserState()) {
    _loadState();
  }

  static const _prefKey = 'noai_rpg_user_state_v2';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null) {
        state = UserState.fromJson(jsonDecode(jsonStr));
      }
    } catch (_) {}
    _checkDailyLogin();
  }

  void _checkDailyLogin() {
    if (!state.hasCompletedOnboarding) return;

    final cfg = LevelConfigService.current;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (state.lastLoginDate == todayStr) return;

    int newStreak = 1;
    bool rewardPending = false;
    int bonusBoxes = 0;

    if (state.lastLoginDate.isNotEmpty) {
      final lastDate = DateTime.tryParse(state.lastLoginDate);
      if (lastDate != null) {
        final lastDay =
            DateTime(lastDate.year, lastDate.month, lastDate.day);
        final today = DateTime(now.year, now.month, now.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 1) {
          newStreak = state.currentStreak + 1;
        }
        // diff > 1: 연속 끊김, newStreak = 1로 유지
      }
    }

    if (newStreak >= cfg.streakDaysRequired) {
      rewardPending = true;
      bonusBoxes = cfg.streakBonusBoxes;
      newStreak = 0; // 목표 일수 달성 후 리셋
    }

    state = state.copyWith(
      lastLoginDate: todayStr,
      currentStreak: newStreak,
      boxesCount: state.boxesCount + bonusBoxes,
      pendingStreakReward: rewardPending,
    );
    _persistState(state);
  }

  Future<void> _persistState(UserState s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(s.toJson()));
    } catch (_) {}
  }

  Future<void> completeOnboarding({
    required String characterType,
    required String goal,
    required List<String> recommendedStats,
  }) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final newState = state.copyWith(
      hasCompletedOnboarding: true,
      characterType: characterType,
      goal: goal,
      recommendedStats: recommendedStats,
      level: 1,
      exp: 0,
      boxesCount: 0,
      inventory: [],
      clearEquipped: true,
      statLevels: const {
        'knowledge': 0,
        'career': 0,
        'health': 0,
        'money': 0,
        'communication': 0,
      },
      lastLoginDate: todayStr,
      currentStreak: 1,
      pendingStreakReward: false,
    );
    state = newState;
    await _persistState(newState);
  }

  // EXP 추가 후 레벨업 여부를 반환합니다.
  Future<int> addExp(int amount) async {
    final expPerLevel = LevelConfigService.current.expPerLevel;
    int tempExp = state.exp + amount;
    int tempLevel = state.level;
    int levelsGained = 0;
    while (tempExp >= expPerLevel) {
      tempExp -= expPerLevel;
      tempLevel++;
      levelsGained++;
    }
    final newState = state.copyWith(level: tempLevel, exp: tempExp);
    state = newState;
    await _persistState(newState);
    return levelsGained;
  }

  Future<void> addStatLevels(List<String> stats) async {
    final newStatLevels = Map<String, int>.from(state.statLevels);
    for (final stat in stats) {
      newStatLevels[stat] = (newStatLevels[stat] ?? 0) + 1;
    }
    final newState = state.copyWith(statLevels: newStatLevels);
    state = newState;
    await _persistState(newState);
  }

  void clearPendingStreakReward() {
    state = state.copyWith(pendingStreakReward: false);
  }

  Future<void> gainBox(int count) async {
    final newState = state.copyWith(boxesCount: state.boxesCount + count);
    state = newState;
    await _persistState(newState);
  }

  Future<bool> openBox(String item) async {
    if (state.boxesCount <= 0) return false;
    final newInventory = List<String>.from(state.inventory);
    if (!newInventory.contains(item)) newInventory.add(item);
    final newState = state.copyWith(
      boxesCount: state.boxesCount - 1,
      inventory: newInventory,
    );
    state = newState;
    await _persistState(newState);
    return true;
  }

  Future<void> equipAccessory(String? item) async {
    final UserState newState;
    if (item == null) {
      newState = state.copyWith(clearEquipped: true);
    } else {
      if (!state.inventory.contains(item)) return;
      newState = state.copyWith(equippedAccessory: item);
    }
    state = newState;
    await _persistState(newState);
  }

  Future<void> resetAll() async {
    state = const UserState();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      await prefs.remove(QuestRepositoryImpl.sharedPrefKey);
    } catch (_) {}
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
