import '../../../core/constants/game_balance.dart';
import 'entities/character.dart';

/// 게이지가 낮아져도 캐릭터는 "죽지" 않고 기분 단계만 변한다.
/// 처벌보다 재회의 기쁨을 강조하기 위해, 다시 케어하면 즉시 happy로 돌아온다.
enum CharacterMood { happy, moping, sulking, longing }

extension CharacterMoodX on Character {
  /// 세 게이지 중 가장 낮은 값을 기준으로 기분을 판정한다.
  CharacterMood get mood {
    final worst = [satiation, cleanliness, affection].reduce(
      (a, b) => a < b ? a : b,
    );
    if (worst <= GameBalance.moodLongingThreshold) return CharacterMood.longing;
    if (worst <= GameBalance.moodSulkingThreshold) return CharacterMood.sulking;
    if (worst <= GameBalance.moodMopingThreshold) return CharacterMood.moping;
    return CharacterMood.happy;
  }
}
