import 'dart:convert';
import 'dart:math';
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
import '../core/services/supabase_service.dart';
import '../core/config/supabase_config.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage;
  final _supabase = SupabaseService();

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

  // 스페셜 미션
  List<SpecialMission> _specialMissionPool = [];
  SpecialMission? _todaySpecialMission;
  SpecialMissionClaim? _specialClaim;   // null = 아직 아무도 안 함
  bool _specialLoading = false;
  String? _specialError;
  String? _deviceId;

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
  SpecialMissionClaim? get specialClaim => _specialClaim;
  bool get specialLoading => _specialLoading;
  String? get specialError => _specialError;
  String? get deviceId => _deviceId;
  bool get specialClaimedByMe =>
      _specialClaim != null && _deviceId != null && _specialClaim!.isMe(_deviceId!);

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
    _deviceId = await _ensureDeviceId();

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

    // 스페셜 미션 클레임 상태는 백그라운드에서 비동기 로드
    if (_isOnboarded) _fetchSpecialMissionClaim();
  }

  // ─── 스페셜 미션 ──────────────────────────────────────────────────────────

  Future<void> _loadSpecialMissionPool() async {
    try {
      final raw = await rootBundle.loadString('assets/special_missions.json');
      final list = jsonDecode(raw) as List;
      _specialMissionPool =
          list.map((e) => SpecialMission.fromJson(e as Map<String, dynamic>)).toList();
      _todaySpecialMission = _pickTodayMission();
    } catch (_) {
      // JSON 로드 실패 시 스페셜 미션 없음
    }
  }

  SpecialMission? _pickTodayMission() {
    if (_specialMissionPool.isEmpty) return null;
    final epoch = DateTime(2024, 1, 1);
    final dayIndex = DateTime.now().difference(epoch).inDays;
    return _specialMissionPool[dayIndex % _specialMissionPool.length];
  }

  Future<void> _fetchSpecialMissionClaim() async {
    if (_todaySpecialMission == null) return;
    if (!SupabaseConfig.isConfigured) return;

    _specialLoading = true;
    _specialError = null;
    notifyListeners();

    try {
      _specialClaim = await _supabase.fetchTodayClaim(_todayDateString());
    } catch (e) {
      _specialError = '네트워크 오류. 다시 시도해주세요.';
    } finally {
      _specialLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSpecialMission() => _fetchSpecialMissionClaim();

  Future<SpecialClaimResult> claimSpecialMission() async {
    if (_todaySpecialMission == null) throw StateError('No special mission');
    if (_userProfile == null) throw StateError('No user profile');
    if (_deviceId == null) throw StateError('No device ID');

    _specialLoading = true;
    notifyListeners();

    try {
      final result = await _supabase.claimMission(
        date: _todayDateString(),
        nickname: _userProfile!.nickname,
        deviceId: _deviceId!,
      );

      _specialClaim = result.existingClaim;

      if (result.isWinner) {
        // XP 지급
        final xpEarned = _todaySpecialMission!.bonusXp;
        final oldLevel = _userProfile!.level;
        final newTotalXP = _userProfile!.totalXP + xpEarned;
        final newLevel = _computeLevel(newTotalXP);
        final didLevelUp = newLevel > oldLevel;
        final newTitle = didLevelUp ? LevelTitles.unlockedAt(newLevel) : null;

        _userProfile = _userProfile!.copyWith(totalXP: newTotalXP, level: newLevel);
        await _storage.saveUserProfile(_userProfile!.toJsonString());

        notifyListeners();
        return SpecialClaimResult(
          isWinner: true,
          winner: result.existingClaim!,
          xpEarned: xpEarned,
          didLevelUp: didLevelUp,
          newLevel: newLevel,
          newTitle: newTitle,
        );
      } else {
        notifyListeners();
        return SpecialClaimResult(
          isWinner: false,
          winner: result.existingClaim!,
          xpEarned: 0,
          didLevelUp: false,
          newLevel: _userProfile!.level,
        );
      }
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
    final today = _todayDateString();
    final savedDate = _storage.getTodayQuestDate();
    final savedIds = _storage.getTodayQuestIds();

    if (savedDate == today && savedIds.isNotEmpty) {
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
      _todayDateString(),
    );
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    _userProfile = profile;
    _isOnboarded = true;
    await _storage.saveUserProfile(profile.toJsonString());
    await _assignNewTodayQuests();
    _isLoading = false;
    notifyListeners();
    _fetchSpecialMissionClaim();
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
    _specialClaim = null;
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

  Future<String> _ensureDeviceId() async {
    final existing = _storage.getDeviceId();
    if (existing != null) return existing;
    final newId = _generateUuid();
    await _storage.saveDeviceId(newId);
    return newId;
  }

  static String _generateUuid() {
    final rng = Random.secure();
    final bytes = List.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${bytes.sublist(0, 4).map(hex).join()}-'
        '${bytes.sublist(4, 6).map(hex).join()}-'
        '${bytes.sublist(6, 8).map(hex).join()}-'
        '${bytes.sublist(8, 10).map(hex).join()}-'
        '${bytes.sublist(10).map(hex).join()}';
  }

  static int _computeLevel(int totalXP) => UserProfile.computeLevel(totalXP);

  static String _todayDateString() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String _yesterdayDateString() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
}
