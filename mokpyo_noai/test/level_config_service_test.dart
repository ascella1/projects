import 'package:flutter_test/flutter_test.dart';
import 'package:mokpyo_noai/core/services/level_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LevelConfigService.load()는 assets/data/mokpyo_level_config.json을 파싱한다',
      () async {
    final cfg = await LevelConfigService.load();

    expect(cfg.expPerLevel, 100);
    expect(cfg.rewardExpByDepth, {1: 100, 2: 50, 3: 30, 4: 10});
    expect(cfg.tierUnlockLevelByDepth, {3: 5, 2: 10, 1: 20});
    expect(cfg.streakDaysRequired, 7);
    expect(cfg.streakBonusBoxes, 3);
    expect(cfg.moodNeutralAfterDays, 1);
    expect(cfg.moodHungryAfterDays, 2);
  });

  test('load() 이후 current는 같은 캐시 인스턴스를 즉시 반환한다', () async {
    final loaded = await LevelConfigService.load();
    expect(LevelConfigService.current.expPerLevel, loaded.expPerLevel);
  });

  test('LevelConfig.fallback()은 JSON과 동일한 기본값을 제공한다', () {
    final fallback = LevelConfig.fallback();
    expect(fallback.expPerLevel, 100);
    expect(fallback.rewardExpByDepth[4], 10);
    expect(fallback.tierUnlockLevelByDepth[1], 20);
    expect(fallback.moodNeutralAfterDays, 1);
    expect(fallback.moodHungryAfterDays, 2);
  });
}
