import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/models/quest.dart';
import '../core/models/quest_result.dart';
import '../core/models/user_profile.dart';
import '../core/models/experience_entry.dart';
import '../core/models/special_mission.dart';
import '../core/services/storage_service.dart';
import '../core/services/quest_service.dart';
import '../core/services/quest_database.dart';
import '../core/services/level_titles.dart';
import '../core/services/stat_config.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage;

  AppState(this._storage);

  bool _isLoading = true;
  bool _isOnboarded = false;
  ThemeMode _themeMode = ThemeMode.dark;
  UserProfile? _userProfile;
  List<Quest> _todayQuests = [];
  Set<String> _todayCompletedIds = {};
  List<ExperienceEntry> _experiences = [];
  Map<String, int> _stats = {
    'exploration': 0,
    'social': 0,
    'courage': 0,
    'creativity': 0,
    'spontaneity': 0,
    'adaptability': 0,
  };

  // 스페셜 미션 — 4시간 슬롯 기반
  List<SpecialMission> _specialMissionPool = [];
  SpecialMission? _todaySpecialMission;
  bool _specialCompletedThisSlot = false;
  bool _specialLoading = false;
  String? _specialError;

  // Getters
  bool get isLoading => _isLoading;
  bool get isOnboarded => _isOnboarded;
  ThemeMode get themeMode => _themeMode;
  UserProfile? get userProfile => _userProfile;
  List<Quest> get todayQuests => List.unmodifiable(_todayQuests);
  Set<String> get todayCompletedIds => Set.unmodifiable(_todayCompletedIds);
  bool isQuestCompleted(String questId) => _todayCompletedIds.contains(questId);
  bool get allTodayQuestsCompleted =>
      _todayQuests.isNotEmpty &&
      _todayQuests.every((q) => _todayCompletedIds.contains(q.id));

  List<ExperienceEntry> get experiences => List.unmodifiable(_experiences);
  Map<String, int> get stats => Map.unmodifiable(_stats);

  int get level => _userProfile?.level ?? 1;
  int get totalXP => _userProfile?.totalXP ?? 0;
  int get streak => _userProfile?.currentStreak ?? 0;

  // 스페셜 미션 Getters
  SpecialMission? get todaySpecialMission => _todaySpecialMission;
  bool get specialCompletedThisSlot => _specialCompletedThisSlot;
  bool get specialLoading => _specialLoading;
  String? get specialError => _specialError;

  // ─── 초기화 ───────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _storage.init(),
      LevelTitles.load(),
      StatConfig.load(),
    ]);

    _themeMode = _storage.getThemeMode() == 'light' ? ThemeMode.light : ThemeMode.dark;
    _isOnboarded = _storage.isOnboarded;

    // 스페셜 미션 풀 로드 (로컬 JSON)
    await _loadSpecialMissionPool();

    if (_isOnboarded) {
      final profileJson = _storage.getUserProfile();
      if (profileJson != null) {
        _userProfile = UserProfile.fromJsonString(profileJson);
      }

      final experiencesJson = _storage.getExperiences();
      if (experiencesJson != null) {
        _experiences = ExperienceEntry.listFromJson(experiencesJson);
      }

      final statsJson = _storage.getStats();
      if (statsJson != null) {
        final decoded = jsonDecode(statsJson) as Map<String, dynamic>;
        _stats = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      }

      await _loadOrRefreshTodayQuests();
    }

    _isLoading = false;
    notifyListeners();

    // 스페셜 미션 슬롯 완료 여부 확인 (로컬)
    if (_isOnboarded) _checkSpecialSlotCompletion();
  }

  // ─── 스페셜 미션 (4시간 슬롯 기반) ──────────────────────────────────────────

  Future<void> _loadSpecialMissionPool() async {
    try {
      final raw = await rootBundle.loadString('assets/special_missions.json');
      final list = jsonDecode(raw) as List;
      _specialMissionPool =
          list.map((e) => SpecialMission.fromJson(e as Map<String, dynamic>)).toList();
      _todaySpecialMission = _pickCurrentMission();
    } catch (_) {
      // JSON 로드 실패 시 스페셜 미션 없음
    }
  }

  // 오늘 날짜 기반 미션 선택 (24시간 로테이션)
  SpecialMission? _pickCurrentMission() {
    if (_specialMissionPool.isEmpty) return null;
    final epoch = DateTime(2024, 1, 1);
    final totalDays = DateTime.now().difference(epoch).inDays;
    return _specialMissionPool[totalDays % _specialMissionPool.length];
  }

  // 스페셜 미션 키: 하루 단위
  static String _currentSlotKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 기본 퀘스트 슬롯 키: 4시간 단위 (예: "2024-08-30-slot-2")
  static String _currentQuestSlotKey() {
    final now = DateTime.now();
    final slotIndex = now.hour ~/ 4;
    return '${DateFormat('yyyy-MM-dd').format(now)}-slot-$slotIndex';
  }

  void _checkSpecialSlotCompletion() {
    final completedSlot = _storage.getCompletedSpecialSlot();
    _specialCompletedThisSlot = completedSlot == _currentSlotKey();
    notifyListeners();
  }

  // 슬롯이 바뀌었을 때 UI에서 호출
  void refreshSpecialMission() {
    _todaySpecialMission = _pickCurrentMission();
    _checkSpecialSlotCompletion();
  }

  Future<SpecialClaimResult> claimSpecialMission() async {
    if (_todaySpecialMission == null) throw StateError('No special mission');
    if (_userProfile == null) throw StateError('No user profile');

    _specialLoading = true;
    notifyListeners();

    try {
      final xpEarned = _todaySpecialMission!.bonusXp;
      final oldLevel = _userProfile!.level;
      final newTotalXP = _userProfile!.totalXP + xpEarned;
      final newLevel = _computeLevel(newTotalXP);
      final didLevelUp = newLevel > oldLevel;
      final newTitle = didLevelUp ? LevelTitles.unlockedAt(newLevel) : null;

      _userProfile = _userProfile!.copyWith(totalXP: newTotalXP, level: newLevel);
      await _storage.saveUserProfile(_userProfile!.toJsonString());
      await _storage.saveCompletedSpecialSlot(_currentSlotKey());
      _specialCompletedThisSlot = true;

      notifyListeners();
      return SpecialClaimResult(
        xpEarned: xpEarned,
        didLevelUp: didLevelUp,
        newLevel: newLevel,
        newTitle: newTitle,
      );
    } catch (e) {
      _specialError = '오류가 발생했어요. 다시 시도해주세요.';
      notifyListeners();
      rethrow;
    } finally {
      _specialLoading = false;
      notifyListeners();
    }
  }

  // ─── 일반 퀘스트 ──────────────────────────────────────────────────────────

  Future<void> _loadOrRefreshTodayQuests() async {
    final slotKey = _currentQuestSlotKey();
    final savedDate = _storage.getTodayQuestDate();
    final savedIds = _storage.getTodayQuestIds();

    if (savedDate == slotKey && savedIds.isNotEmpty) {
      _todayQuests = savedIds
          .map((id) => QuestDatabase.findById(id))
          .whereType<Quest>()
          .toList();
      _todayCompletedIds = _storage.getTodayCompletedIds();
    } else {
      await _assignNewTodayQuests();
    }
  }

  Future<void> _assignNewTodayQuests() async {
    if (_userProfile == null) return;

    final quests = QuestService.recommendMultiple(
      profile: _userProfile!,
      recentlyCompletedIds: _userProfile!.completedQuestIds,
      count: 2,
    );

    _todayQuests = quests;
    _todayCompletedIds = {};
    await _storage.saveTodayQuests(
      quests.map((q) => q.id).toList(),
      _currentQuestSlotKey(),
    );
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    _userProfile = profile;
    _isOnboarded = true;
    await _storage.saveUserProfile(profile.toJsonString());
    await _assignNewTodayQuests();
    _isLoading = false;
    notifyListeners();
    _checkSpecialSlotCompletion();
  }

  Future<QuestResult> completeQuest(String questId) async {
    final quest = _todayQuests.firstWhere((q) => q.id == questId);
    if (_userProfile == null) throw StateError('No user profile');
    if (_todayCompletedIds.contains(questId)) {
      throw StateError('Quest already completed');
    }

    final xpEarned = QuestService.computeXP(quest);
    final boosts = QuestService.computeStatBoosts(quest);

    for (final e in boosts.entries) {
      _stats[e.key] = (_stats[e.key] ?? 0) + e.value;
    }

    final oldLevel = _userProfile!.level;
    final newTotalXP = _userProfile!.totalXP + xpEarned;
    final newLevel = _computeLevel(newTotalXP);
    final didLevelUp = newLevel > oldLevel;
    final newTitle = didLevelUp ? LevelTitles.unlockedAt(newLevel) : null;

    final today = _todayDateString();
    final lastDate = _userProfile!.lastQuestDate;

    int newStreak;
    if (lastDate == _yesterdayDateString()) {
      newStreak = _userProfile!.currentStreak + 1;
    } else if (lastDate == today) {
      newStreak = _userProfile!.currentStreak;
    } else {
      newStreak = 1;
    }

    final newLongest =
        newStreak > _userProfile!.longestStreak ? newStreak : _userProfile!.longestStreak;

    final newCompleted = [questId, ..._userProfile!.completedQuestIds];

    final updatedProfile = _userProfile!.copyWith(
      totalXP: newTotalXP,
      level: newLevel,
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastQuestDate: today,
      completedQuestIds: newCompleted,
    );

    final entry = ExperienceEntry(
      id: '${questId}_${DateTime.now().millisecondsSinceEpoch}',
      questId: questId,
      title: quest.title,
      description: quest.description,
      emoji: quest.emoji,
      number: _experiences.length + 1,
      xpEarned: xpEarned,
      statBoosts: boosts,
      completedAt: today,
      category: quest.categoryName,
    );

    _experiences = [entry, ..._experiences];
    _userProfile = updatedProfile;
    _todayCompletedIds = {..._todayCompletedIds, questId};

    await _storage.markQuestCompleted(questId);
    await _storage.saveUserProfile(updatedProfile.toJsonString());
    await _storage.saveExperiences(ExperienceEntry.listToJson(_experiences));
    await _storage.saveStats(jsonEncode(_stats));

    notifyListeners();
    return QuestResult(
      entry: entry,
      didLevelUp: didLevelUp,
      newLevel: newLevel,
      newTitle: newTitle,
    );
  }

  // ─── 설정 ─────────────────────────────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  Future<void> updateComfortZone(ComfortLevel zone) async {
    if (_userProfile == null) return;
    _userProfile = _userProfile!.copyWith(comfortZone: zone);
    await _storage.saveUserProfile(_userProfile!.toJsonString());
    notifyListeners();
  }

  Future<void> refreshQuests() async {
    await _assignNewTodayQuests();
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _storage.clear();
    _isOnboarded = false;
    _userProfile = null;
    _todayQuests = [];
    _todayCompletedIds = {};
    _experiences = [];
    _specialCompletedThisSlot = false;
    _specialError = null;
    _stats = {
      'exploration': 0,
      'social': 0,
      'courage': 0,
      'creativity': 0,
      'spontaneity': 0,
      'adaptability': 0,
    };
    notifyListeners();
  }

  // ─── 헬퍼 ─────────────────────────────────────────────────────────────────

  static int _computeLevel(int totalXP) => UserProfile.computeLevel(totalXP);

  static String _todayDateString() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String _yesterdayDateString() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
}
