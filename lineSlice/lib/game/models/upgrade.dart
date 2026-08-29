/// 강화 종류. 스펙 8번 강화 풀.
enum UpgradeType {
  wideSlice,
  criticalSlice,
  slowMastery,
  timingGrace,
  comboKeep,
  guardianShield,
  penetratingCut,
}

class UpgradeDef {
  const UpgradeDef({
    required this.type,
    required this.name,
    required this.description,
    required this.maxLevel,
  });

  final UpgradeType type;
  final String name;
  final String description;
  final int maxLevel;
}

const List<UpgradeDef> kUpgradeDefs = [
  UpgradeDef(
    type: UpgradeType.wideSlice,
    name: '와이드 슬라이스',
    description: '한 스와이프로 절단 가능한 장애물 수 +1',
    maxLevel: 3,
  ),
  UpgradeDef(
    type: UpgradeType.criticalSlice,
    name: '크리티컬 슬라이스',
    description: '크리티컬 확률 +8%',
    maxLevel: 5,
  ),
  UpgradeDef(
    type: UpgradeType.slowMastery,
    name: '슬로우 마스터리',
    description: '슬로우모션 지속시간 +0.05초',
    maxLevel: 5,
  ),
  UpgradeDef(
    type: UpgradeType.timingGrace,
    name: '타이밍 그레이스',
    description: '절단 판정 윈도우 +10%',
    maxLevel: 3,
  ),
  UpgradeDef(
    type: UpgradeType.comboKeep,
    name: '콤보 킵',
    description: '콤보 유지시간 +0.3초',
    maxLevel: 4,
  ),
  UpgradeDef(
    type: UpgradeType.guardianShield,
    name: '가디언 실드',
    description: '실드 +1개',
    maxLevel: 3,
  ),
  UpgradeDef(
    type: UpgradeType.penetratingCut,
    name: '관통 절단',
    description: '스와이프 궤적 전체가 관통하며, 절단 수 제한을 무시한다',
    maxLevel: 1,
  ),
];

UpgradeDef upgradeDefFor(UpgradeType type) =>
    kUpgradeDefs.firstWhere((d) => d.type == type);
