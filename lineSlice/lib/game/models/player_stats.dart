import 'upgrade.dart';

/// 레벨 0 기본 스탯 (스펙 5번) + 강화 레벨을 반영한 파생 스탯.
class PlayerStats {
  PlayerStats()
      : upgradeLevels = {for (final t in UpgradeType.values) t: 0};

  final Map<UpgradeType, int> upgradeLevels;

  int get sliceCount => 1 + upgradeLevels[UpgradeType.wideSlice]!;

  double get criticalChance =>
      (upgradeLevels[UpgradeType.criticalSlice]! * 0.08).clamp(0.0, 1.0);

  double get slowMotionDuration =>
      0.15 + upgradeLevels[UpgradeType.slowMastery]! * 0.05;

  static const double slowMotionTimeScale = 0.3;

  double get cutJudgementWindow =>
      0.25 * (1 + upgradeLevels[UpgradeType.timingGrace]! * 0.10);

  double get comboHoldDuration =>
      1.5 + upgradeLevels[UpgradeType.comboKeep]! * 0.3;

  int get shieldCount => upgradeLevels[UpgradeType.guardianShield]!;

  bool get hasPenetratingCut => upgradeLevels[UpgradeType.penetratingCut]! > 0;

  double get xpMagnetRadius => 100.0;

  int levelFor(UpgradeType type) => upgradeLevels[type]!;

  bool isMaxed(UpgradeType type) =>
      upgradeLevels[type]! >= upgradeDefFor(type).maxLevel;

  void applyUpgrade(UpgradeType type) {
    final def = upgradeDefFor(type);
    final current = upgradeLevels[type]!;
    if (current < def.maxLevel) {
      upgradeLevels[type] = current + 1;
    }
  }

  /// 만렙이 아닌 강화 중 무작위 [count]개를 뽑는다.
  List<UpgradeDef> rollChoices(int count) {
    final available = kUpgradeDefs.where((d) => !isMaxed(d.type)).toList();
    available.shuffle();
    return available.take(count).toList();
  }
}
