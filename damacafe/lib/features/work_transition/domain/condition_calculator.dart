import '../../../core/constants/game_balance.dart';
import '../../character/domain/entities/character.dart';

/// 출근 시: 집 케어 상태(배고픔/청결/애정도)를 스냅샷으로 찍어 컨디션 점수로 환산한다.
int calculateConditionScore(Character character) {
  final average = (character.satiation + character.cleanliness + character.affection) / 3;
  return average.round().clamp(GameBalance.minGauge, GameBalance.maxGauge);
}

class OrderOutcome {
  const OrderOutcome({required this.coins, required this.stars});

  final int coins;
  final int stars;
}

/// 컨디션 점수가 낮으면 요리 성공률/손님 만족도에 페널티를 준다.
/// 페널티 여부는 즉시 서빙 결과에 반영되지만, 코인 총액은 퇴근 시점에만 공개된다.
OrderOutcome evaluateOrder({required int recipeReward, required int conditionScore}) {
  final isPenalized = conditionScore < GameBalance.conditionPenaltyThreshold;
  final coins = isPenalized ? (recipeReward * 0.6).round() : recipeReward;
  final stars = isPenalized ? 3 : 5;
  return OrderOutcome(coins: coins, stars: stars);
}
