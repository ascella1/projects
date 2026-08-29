import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../character/presentation/providers/character_provider.dart';
import '../../domain/condition_calculator.dart';
import '../../domain/settlement_calculator.dart';
import '../../domain/work_session.dart';

part 'work_session_provider.g.dart';

/// 출근-퇴근 연결 로직의 핵심 상태. 집 케어 상태 스냅샷(컨디션 점수)과
/// 카페 세션 동안 쌓인 코인/주문 수를 들고 있다가 퇴근 시 캐릭터에 정산한다.
/// keepAlive: clockIn()은 아직 아무도 watch하지 않는 홈 화면에서 호출되므로,
/// autoDispose였다면 비동기 대기 중 provider가 폐기되어 상태 반영이 유실된다.
@Riverpod(keepAlive: true)
class WorkSessionNotifier extends _$WorkSessionNotifier {
  @override
  WorkSession build() => WorkSession.initial;

  Future<void> clockIn() async {
    final character = await ref.read(characterProvider.future);
    state = WorkSession.initial.copyWith(
      isAtWork: true,
      conditionScore: calculateConditionScore(character),
    );
  }

  void recordOrderResult(OrderOutcome outcome) {
    state = state.copyWith(
      sessionCoins: state.sessionCoins + outcome.coins,
      ordersServed: state.ordersServed + 1,
    );
  }

  Future<SettlementResult> clockOut() async {
    final result = buildSettlement(
      conditionScore: state.conditionScore,
      sessionCoins: state.sessionCoins,
      ordersServed: state.ordersServed,
    );
    await ref
        .read(characterProvider.notifier)
        .applySettlement(coinsEarned: state.sessionCoins);
    state = WorkSession.initial;
    return result;
  }
}
