import 'package:flutter_test/flutter_test.dart';
import 'package:mokpyo_noai/features/quest/presentation/providers/user_provider.dart';

void main() {
  test('UserState.toJson/fromJson은 lastRoutineDate/lastGreetedDate를 보존한다', () {
    const state = UserState(
      hasCompletedOnboarding: true,
      characterType: 'cat',
      goal: '10kg 다이어트',
      lastRoutineDate: '2026-07-10',
      lastGreetedDate: '2026-07-13',
    );

    final restored = UserState.fromJson(state.toJson());

    expect(restored.lastRoutineDate, '2026-07-10');
    expect(restored.lastGreetedDate, '2026-07-13');
  });

  test('필드가 없는 옛 저장값을 읽어도 빈 문자열로 안전하게 기본값 처리된다', () {
    final restored = UserState.fromJson({
      'hasCompletedOnboarding': true,
      'characterType': 'fox',
      'goal': '영어 공부',
    });

    expect(restored.lastRoutineDate, '');
    expect(restored.lastGreetedDate, '');
  });
}
