/// HUD 렌더링용 불변 스냅샷. [LineSliceGame]이 매 프레임 갱신해서
/// ValueNotifier로 흘려보낸다.
class HudSnapshot {
  const HudSnapshot({
    required this.hp,
    required this.maxHp,
    required this.shield,
    required this.level,
    required this.xpCurrent,
    required this.xpToNext,
    required this.combo,
    required this.elapsedSeconds,
  });

  final int hp;
  final int maxHp;
  final int shield;
  final int level;
  final int xpCurrent;
  final int xpToNext;
  final int combo;
  final double elapsedSeconds;

  static const initial = HudSnapshot(
    hp: 3,
    maxHp: 3,
    shield: 0,
    level: 1,
    xpCurrent: 0,
    xpToNext: 50,
    combo: 0,
    elapsedSeconds: 0,
  );
}
