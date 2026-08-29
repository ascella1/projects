import 'package:damacafe/features/work_transition/domain/settlement_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('세션 동안 쌓인 코인/주문 수를 그대로 정산 결과에 담는다', () {
    final result = buildSettlement(conditionScore: 80, sessionCoins: 45, ordersServed: 3);

    expect(result.conditionScore, 80);
    expect(result.totalCoinsEarned, 45);
    expect(result.ordersServed, 3);
  });
}
