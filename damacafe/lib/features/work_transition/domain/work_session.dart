/// 출근~퇴근 사이에만 유지되는 세션 상태. 영속 저장하지 않는다.
class WorkSession {
  const WorkSession({
    required this.isAtWork,
    required this.conditionScore,
    required this.sessionCoins,
    required this.ordersServed,
  });

  static const WorkSession initial = WorkSession(
    isAtWork: false,
    conditionScore: 100,
    sessionCoins: 0,
    ordersServed: 0,
  );

  final bool isAtWork;
  final int conditionScore;
  final int sessionCoins;
  final int ordersServed;

  WorkSession copyWith({
    bool? isAtWork,
    int? conditionScore,
    int? sessionCoins,
    int? ordersServed,
  }) {
    return WorkSession(
      isAtWork: isAtWork ?? this.isAtWork,
      conditionScore: conditionScore ?? this.conditionScore,
      sessionCoins: sessionCoins ?? this.sessionCoins,
      ordersServed: ordersServed ?? this.ordersServed,
    );
  }
}
