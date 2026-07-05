import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserState {
  final bool hasCompletedOnboarding;
  final String characterType; // 'cat', 'dog', 'fox'
  final String goal;
  final List<String> recommendedStats;
  final int level;
  final int exp;
  final int boxesCount;
  final List<String> inventory;
  final String? equippedAccessory;

  UserState({
    this.hasCompletedOnboarding = false,
    this.characterType = 'fox',
    this.goal = '',
    this.recommendedStats = const [],
    this.level = 1,
    this.exp = 0,
    this.boxesCount = 0,
    this.inventory = const [],
    this.equippedAccessory,
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
  }) {
    return UserState(
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      characterType: characterType ?? this.characterType,
      goal: goal ?? this.goal,
      recommendedStats: recommendedStats ?? this.recommendedStats,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      boxesCount: boxesCount ?? this.boxesCount,
      inventory: inventory ?? this.inventory,
      equippedAccessory: clearEquipped ? null : (equippedAccessory ?? this.equippedAccessory),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'characterType': characterType,
      'goal': goal,
      'recommendedStats': recommendedStats,
      'level': level,
      'exp': exp,
      'boxesCount': boxesCount,
      'inventory': inventory,
      'equippedAccessory': equippedAccessory,
    };
  }

  factory UserState.fromJson(Map<String, dynamic> map) {
    return UserState(
      hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? false,
      characterType: map['characterType'] ?? 'fox',
      goal: map['goal'] ?? '',
      recommendedStats: List<String>.from(map['recommendedStats'] ?? []),
      level: map['level'] ?? 1,
      exp: map['exp'] ?? 0,
      boxesCount: map['boxesCount'] ?? 0,
      inventory: List<String>.from(map['inventory'] ?? []),
      equippedAccessory: map['equippedAccessory'],
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState()) {
    _loadState();
  }

  static const _prefKey = 'rpg_user_state';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null) {
        state = UserState.fromJson(jsonDecode(jsonStr));
      }
    } catch (_) {
      // 캐시 로드 에러 시 디폴트 상태 유지
    }
  }

  Future<void> _saveState(UserState newState) async {
    state = newState;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(newState.toJson()));
    } catch (_) {}
  }

  Future<void> completeOnboarding({
    required String characterType,
    required String goal,
    required List<String> recommendedStats,
  }) async {
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
    );
    await _saveState(newState);
  }

  Future<void> addExp(int amount) async {
    int tempExp = state.exp + amount;
    int tempLevel = state.level;
    while (tempExp >= 100) {
      tempExp -= 100;
      tempLevel += 1;
    }
    
    final newState = state.copyWith(
      level: tempLevel,
      exp: tempExp,
    );
    await _saveState(newState);
  }

  Future<void> gainBox(int count) async {
    final newState = state.copyWith(
      boxesCount: state.boxesCount + count,
    );
    await _saveState(newState);
  }

  Future<bool> openBox(String item) async {
    if (state.boxesCount <= 0) return false;
    
    final newInventory = List<String>.from(state.inventory);
    if (!newInventory.contains(item)) {
      newInventory.add(item);
    }
    
    final newState = state.copyWith(
      boxesCount: state.boxesCount - 1,
      inventory: newInventory,
    );
    await _saveState(newState);
    return true;
  }

  Future<void> equipAccessory(String? item) async {
    if (item == null) {
      final newState = state.copyWith(clearEquipped: true);
      await _saveState(newState);
    } else {
      if (state.inventory.contains(item)) {
        final newState = state.copyWith(equippedAccessory: item);
        await _saveState(newState);
      }
    }
  }

  Future<void> resetAll() async {
    await _saveState(UserState());
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
