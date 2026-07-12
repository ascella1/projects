import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mokpyo_noai/core/services/level_config_service.dart';
import 'package:mokpyo_noai/features/home/presentation/views/journey_map_screen.dart';
import 'package:mokpyo_noai/features/quest/data/repositories/quest_repository_impl.dart';
import 'package:mokpyo_noai/features/quest/domain/entities/quest_entity.dart';
import 'package:mokpyo_noai/features/quest/presentation/providers/quest_provider.dart';
import 'package:mokpyo_noai/features/quest/presentation/providers/user_provider.dart';

Quest _quest(int depth, String title, {QuestStatus status = QuestStatus.todo}) =>
    Quest(
      id: 'q_${depth}_$title',
      goalId: 'g_active',
      title: title,
      depth: depth,
      status: status,
      difficulty: QuestDifficulty.easy,
      rewardExp: 10,
      rewardStats: const ['career'],
      dueDate: DateTime.now(),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LevelConfigService.load();
  });

  testWidgets('잠금 해제된 일일 퀘스트를 탭하면 완료 처리되고, 잠긴 대목표는 안내 스낵바만 뜬다',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 레벨 1(기본값)인 유저를 가정 - 대목표(Lv.20 해금)는 잠겨 있어야 한다.
    final quests = [
      _quest(1, '10kg 다이어트'),
      _quest(4, '물 마시기'),
    ];
    await QuestRepositoryImpl().createQuests(quests);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: const JourneyMapScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('10kg 다이어트'), findsOneWidget);
    expect(find.text('물 마시기'), findsOneWidget);
    expect(find.text('Lv.20 해금'), findsOneWidget);

    // 잠긴 대목표를 탭하면 완료되지 않고 안내만 뜬다.
    await tester.tap(find.text('10kg 다이어트'));
    await tester.pump();
    expect(find.textContaining('해금돼요'), findsOneWidget);

    final levelBefore = container.read(userProvider).level;

    // 잠금 해제된 일일 퀘스트는 탭하면 바로 완료된다.
    await tester.tap(find.text('물 마시기'));
    await tester.pumpAndSettle();

    final updatedQuests =
        container.read(questListProvider('g_active')).value!;
    final daily = updatedQuests.firstWhere((q) => q.title == '물 마시기');
    expect(daily.status, QuestStatus.completed);
    expect(container.read(userProvider).level, greaterThanOrEqualTo(levelBefore));
  });
}
