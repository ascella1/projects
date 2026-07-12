import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// assets/data/mokpyo_level_config.json에 정의된 레벨업/보상 밸런스 값.
// 코드 수정 없이 JSON만 바꾸면 밸런스를 조절할 수 있다.
class LevelConfig {
  final int expPerLevel;
  final Map<int, int> rewardExpByDepth;
  final Map<int, int> tierUnlockLevelByDepth;
  final int streakDaysRequired;
  final int streakBonusBoxes;

  const LevelConfig({
    required this.expPerLevel,
    required this.rewardExpByDepth,
    required this.tierUnlockLevelByDepth,
    required this.streakDaysRequired,
    required this.streakBonusBoxes,
  });

  factory LevelConfig.fallback() => const LevelConfig(
        expPerLevel: 100,
        rewardExpByDepth: {1: 100, 2: 50, 3: 30, 4: 10},
        tierUnlockLevelByDepth: {3: 5, 2: 10, 1: 20},
        streakDaysRequired: 7,
        streakBonusBoxes: 3,
      );

  factory LevelConfig.fromJson(Map<String, dynamic> map) {
    Map<int, int> parseIntMap(Map<String, dynamic> m) =>
        m.map((key, value) => MapEntry(int.parse(key), value as int));

    final streak = map['streak'] as Map<String, dynamic>;
    return LevelConfig(
      expPerLevel: map['expPerLevel'] as int,
      rewardExpByDepth:
          parseIntMap(map['rewardExpByDepth'] as Map<String, dynamic>),
      tierUnlockLevelByDepth:
          parseIntMap(map['tierUnlockLevels'] as Map<String, dynamic>),
      streakDaysRequired: streak['daysRequired'] as int,
      streakBonusBoxes: streak['bonusBoxes'] as int,
    );
  }
}

class LevelConfigService {
  static const _assetPath = 'assets/data/mokpyo_level_config.json';

  static LevelConfig? _cached;

  // main()에서 runApp 이전에 반드시 await로 호출해야 한다. UserNotifier.addExp
  // 등 동기적으로 LevelConfigService.current를 읽는 코드가 있기 때문이다.
  static Future<LevelConfig> load() async {
    if (_cached != null) return _cached!;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cached = LevelConfig.fromJson(decoded);
    } catch (_) {
      _cached = LevelConfig.fallback();
    }
    return _cached!;
  }

  static LevelConfig get current => _cached ?? LevelConfig.fallback();
}
