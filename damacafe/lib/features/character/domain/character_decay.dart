import '../../../core/constants/game_balance.dart';
import 'entities/character.dart';

/// 마지막 상호작용 이후 경과 시간만큼 게이지를 자연 감소시킨다.
/// 백그라운드 타이머 없이, 화면을 열 때(또는 출근/퇴근 시점) 한 번씩 계산해서 적용하는 방식.
Character applyIdleDecay(Character character, DateTime now) {
  final elapsedHours = now.difference(character.lastUpdatedAt).inMinutes / 60.0;
  if (elapsedHours <= 0) return character;

  int decayed(int value, double perHour) {
    final next = value - (perHour * elapsedHours).round();
    return next.clamp(GameBalance.minGauge, GameBalance.maxGauge);
  }

  return character.copyWith(
    satiation: decayed(character.satiation, GameBalance.satiationDecayPerHour),
    cleanliness: decayed(character.cleanliness, GameBalance.cleanlinessDecayPerHour),
    affection: decayed(character.affection, GameBalance.affectionDecayPerHour),
    lastUpdatedAt: now,
  );
}
