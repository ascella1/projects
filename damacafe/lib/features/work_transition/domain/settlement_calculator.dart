class SettlementResult {
  const SettlementResult({
    required this.conditionScore,
    required this.totalCoinsEarned,
    required this.ordersServed,
  });

  final int conditionScore;
  final int totalCoinsEarned;
  final int ordersServed;
}

/// 퇴근 시: 세션 동안 쌓인 코인/주문 수를 한 번에 공개하는 정산 결과를 만든다.
/// 개별 주문 페널티는 이미 evaluateOrder에서 반영되었으므로, 여기서는 합산만 한다.
SettlementResult buildSettlement({
  required int conditionScore,
  required int sessionCoins,
  required int ordersServed,
}) {
  return SettlementResult(
    conditionScore: conditionScore,
    totalCoinsEarned: sessionCoins,
    ordersServed: ordersServed,
  );
}
