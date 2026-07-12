import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mokpyo_noai/core/services/level_config_service.dart';
import 'package:mokpyo_noai/features/quest/domain/entities/quest_entity.dart';
import 'package:mokpyo_noai/features/quest/presentation/providers/quest_provider.dart';
import 'package:mokpyo_noai/features/quest/presentation/providers/user_provider.dart';
import 'package:mokpyo_noai/main.dart';

void main() {
  testWidgets('7단계 위저드를 끝까지 진행하면 depth별 퀘스트가 올바르게 생성된다',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await LevelConfigService.load();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();

    // Step 0: 캐릭터 선택 (기본값 그대로 두고 진행)
    expect(find.text('선택 완료'), findsOneWidget);
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    // Step 1: 대목표 입력
    expect(find.text('대목표는 뭔가요?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '10kg 다이어트');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // Step 2: 스탯 선택
    expect(find.textContaining('능력치'), findsWidgets);
    await tester.tap(find.text('💪 체력'));
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // Step 3: 중목표 (1개 추가)
    await tester.tap(find.text('항목 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '식습관 조절하기');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // Step 4: 소목표 (1개 추가)
    await tester.tap(find.text('항목 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '매끼 채소 챙겨먹기');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // Step 5: 일일 퀘스트 (1개 추가, 최소 1개 필수)
    await tester.tap(find.text('항목 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '물 500ml 마시기');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // Step 6: 최종 확인 → 제출
    expect(find.text('목표 수락 및 시작!'), findsOneWidget);
    await tester.tap(find.text('목표 수락 및 시작!'));
    await tester.pumpAndSettle();

    final userState = container.read(userProvider);
    expect(userState.hasCompletedOnboarding, isTrue);
    expect(userState.goal, '10kg 다이어트');
    expect(userState.recommendedStats, ['health']);

    final quests = container.read(questListProvider('g_active')).value!;
    final cfg = LevelConfigService.current;

    final mainGoals = quests.where((q) => q.depth == 1).toList();
    final midGoals = quests.where((q) => q.depth == 2).toList();
    final subGoals = quests.where((q) => q.depth == 3).toList();
    final dailyQuests = quests.where((q) => q.depth == 4).toList();

    expect(mainGoals.length, 1);
    expect(midGoals.length, 1);
    expect(subGoals.length, 1);
    expect(dailyQuests.length, 1);

    expect(mainGoals.first.title, '10kg 다이어트');
    expect(mainGoals.first.rewardExp, cfg.rewardExpByDepth[1]);
    expect(midGoals.first.rewardExp, cfg.rewardExpByDepth[2]);
    expect(subGoals.first.rewardExp, cfg.rewardExpByDepth[3]);
    expect(dailyQuests.first.rewardExp, cfg.rewardExpByDepth[4]);

    for (final q in quests) {
      expect(q.rewardStats, ['health']);
      expect(q.status, QuestStatus.todo);
    }

    // 온보딩 완료 후에는 메인 앱(정원 탭)이 보여야 한다.
    expect(find.textContaining('정원사'), findsOneWidget);
  });
}
