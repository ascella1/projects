import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mokpyo_noai/core/services/level_config_service.dart';
import 'package:mokpyo_noai/features/quest/data/repositories/quest_repository_impl.dart';
import 'package:mokpyo_noai/features/quest/domain/entities/quest_entity.dart';
import 'package:mokpyo_noai/features/quest/presentation/providers/quest_provider.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LevelConfigService.load();
  });

  test('addAdHocQuest는 기존 퀘스트를 유지한 채 depth 4 퀘스트를 추가한다', () async {
    final existing = [
      Quest(
        id: 'q_1_main',
        goalId: 'g_active',
        title: '대목표',
        depth: 1,
        status: QuestStatus.todo,
        difficulty: QuestDifficulty.hard,
        rewardExp: 100,
        rewardStats: const ['career'],
        dueDate: DateTime.now(),
      ),
    ];
    await QuestRepositoryImpl().createQuests(existing);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 최초 fetch를 트리거해 상태를 초기화한다.
    container.read(questListProvider('g_active'));
    await Future<void>.delayed(Duration.zero);

    await container.read(questListProvider('g_active').notifier).addAdHocQuest(
          goalId: 'g_active',
          title: '갑자기 영단어 10개 외우기',
          rewardStats: ['knowledge'],
        );

    final quests = container.read(questListProvider('g_active')).value!;
    expect(quests.length, 2);
    expect(quests.any((q) => q.title == '대목표'), isTrue);

    final adhoc = quests.firstWhere((q) => q.title == '갑자기 영단어 10개 외우기');
    expect(adhoc.depth, 4);
    expect(adhoc.status, QuestStatus.todo);
    expect(adhoc.rewardStats, ['knowledge']);
    expect(adhoc.rewardExp, LevelConfigService.current.rewardExpByDepth[4]);
  });
}
