import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyUserProfile = 'user_profile';
  static const _keyTodayQuestIds = 'today_quest_ids';      // JSON list of 3 IDs
  static const _keyTodayQuestDate = 'today_quest_date';
  static const _keyTodayCompletedIds = 'today_completed_ids'; // JSON list
  static const _keyExperiences = 'experiences';
  static const _keyStats = 'character_stats';
  static const _keyThemeMode = 'theme_mode';
  static const _keyDeviceId  = 'device_id';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User Profile
  String? getUserProfile() => _prefs.getString(_keyUserProfile);
  Future<void> saveUserProfile(String json) =>
      _prefs.setString(_keyUserProfile, json);
  bool get isOnboarded => _prefs.containsKey(_keyUserProfile);

  // Today's Quests (3 quests)
  List<String> getTodayQuestIds() {
    final raw = _prefs.getString(_keyTodayQuestIds);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  String? getTodayQuestDate() => _prefs.getString(_keyTodayQuestDate);

  Set<String> getTodayCompletedIds() {
    final raw = _prefs.getString(_keyTodayCompletedIds);
    if (raw == null) return {};
    return Set<String>.from(jsonDecode(raw) as List);
  }

  Future<void> saveTodayQuests(List<String> questIds, String date) async {
    await _prefs.setString(_keyTodayQuestIds, jsonEncode(questIds));
    await _prefs.setString(_keyTodayQuestDate, date);
    await _prefs.setString(_keyTodayCompletedIds, jsonEncode([]));
  }

  Future<void> markQuestCompleted(String questId) async {
    final completed = getTodayCompletedIds()..add(questId);
    await _prefs.setString(_keyTodayCompletedIds, jsonEncode(completed.toList()));
  }

  // Experiences
  String? getExperiences() => _prefs.getString(_keyExperiences);
  Future<void> saveExperiences(String json) =>
      _prefs.setString(_keyExperiences, json);

  // Stats
  String? getStats() => _prefs.getString(_keyStats);
  Future<void> saveStats(String json) =>
      _prefs.setString(_keyStats, json);

  // Theme Mode
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'dark';
  Future<void> saveThemeMode(String mode) => _prefs.setString(_keyThemeMode, mode);

  // Device ID (익명 유저 식별용)
  String? getDeviceId() => _prefs.getString(_keyDeviceId);
  Future<void> saveDeviceId(String id) => _prefs.setString(_keyDeviceId, id);

  Future<void> clear() => _prefs.clear();
}
