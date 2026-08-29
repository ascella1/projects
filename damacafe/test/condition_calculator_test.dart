import 'package:damacafe/features/character/domain/entities/character.dart';
import 'package:damacafe/features/work_transition/domain/condition_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('세 게이지의 평균으로 컨디션 점수를 계산한다', () {
    final character = Character(
      satiation: 90,
      cleanliness: 60,
      affection: 30,
      coins: 0,
      ownedItemIds: const [],
      lastUpdatedAt: DateTime(2026, 1, 1),
    );

    expect(calculateConditionScore(character), 60);
  });

  test('컨디션 점수가 낮으면 요리 보상과 별점에 페널티가 붙는다', () {
    final outcome = evaluateOrder(recipeReward: 20, conditionScore: 30);

    expect(outcome.coins, 12);
    expect(outcome.stars, 3);
  });

  test('컨디션 점수가 충분하면 페널티 없이 전액 지급된다', () {
    final outcome = evaluateOrder(recipeReward: 20, conditionScore: 90);

    expect(outcome.coins, 20);
    expect(outcome.stars, 5);
  });
}
