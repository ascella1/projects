import 'dart:ui';

/// 시간 경과에 따라 등장하는 장애물 종류. 1챕터(대나무숲) 컨셉에 맞춰
/// 죽순 -> 대나무 -> 황금대나무 순서로 등장 풀에 추가된다.
enum ObstacleMaterial {
  shoot(
    label: '죽순',
    unlockTimeSeconds: 0,
    color: Color(0xFF9CCC65),
    cutColor: Color(0xFFE6F4D9),
    cutSoundKey: 'cut_shoot',
  ),
  bamboo(
    label: '대나무',
    unlockTimeSeconds: 30,
    color: Color(0xFF4C8C4A),
    cutColor: Color(0xFFC8E6C0),
    cutSoundKey: 'cut_bamboo',
  ),
  goldenBamboo(
    label: '황금대나무',
    unlockTimeSeconds: 60,
    color: Color(0xFFE8B94A),
    cutColor: Color(0xFFFFF3C4),
    cutSoundKey: 'cut_golden_bamboo',
  );

  const ObstacleMaterial({
    required this.label,
    required this.unlockTimeSeconds,
    required this.color,
    required this.cutColor,
    required this.cutSoundKey,
  });

  final String label;
  final double unlockTimeSeconds;
  final Color color;
  final Color cutColor;
  final String cutSoundKey;

  /// [elapsedSeconds] 시점에 등장 가능한 종류 목록.
  static List<ObstacleMaterial> unlockedAt(double elapsedSeconds) {
    return values.where((m) => elapsedSeconds >= m.unlockTimeSeconds).toList();
  }
}
