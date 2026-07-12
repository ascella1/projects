import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/quest_entity.dart';
import '../../domain/repositories/quest_repository.dart';
import '../../data/repositories/quest_repository_impl.dart';
import 'user_provider.dart';
import '../../../../core/services/notification_service.dart';

class QuestListNotifier extends StateNotifier<AsyncValue<List<Quest>>> {
  final QuestRepository _repository;
  final Ref _ref;

  QuestListNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading());

  Future<void> fetchQuests(String goalId) async {
    try {
      state = const AsyncValue.loading();
      final quests = await _repository.getQuests(goalId);
      state = AsyncValue.data(quests);
      _syncDailyReminder();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 퀘스트 완료 처리. 반환값: 획득한 레벨 수
  Future<int> completeQuest(String questId) async {
    final currentQuests = state.value ?? [];
    try {
      final quest = currentQuests.firstWhere((q) => q.id == questId);
      await _repository.completeQuest(questId);

      state = AsyncValue.data(
        currentQuests
            .map((q) => q.id == questId
                ? q.copyWith(
                    status: QuestStatus.completed,
                    completedAt: DateTime.now())
                : q)
            .toList(),
      );

      final levelsGained =
          await _ref.read(userProvider.notifier).addExp(quest.rewardExp);
      await _ref.read(userProvider.notifier).gainBox(1);
      await _ref
          .read(userProvider.notifier)
          .addStatLevels(quest.rewardStats);

      _syncDailyReminder();
      return levelsGained;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }

  Future<void> failQuest(String questId) async {
    final currentQuests = state.value ?? [];
    try {
      await _repository.failQuest(questId);
      state = AsyncValue.data(
        currentQuests
            .map((q) => q.id == questId
                ? q.copyWith(status: QuestStatus.failed)
                : q)
            .toList(),
      );
      _syncDailyReminder();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 목표 입력 위저드에서 만든 퀘스트 목록으로 교체 저장.
  Future<void> replaceQuests(List<Quest> quests) async {
    await _repository.createQuests(quests);
    state = AsyncValue.data(quests);
    _syncDailyReminder();
  }

  // 오늘의 일일 퀘스트(depth==4) 완료 여부에 따라 알림을 재예약/취소한다.
  void _syncDailyReminder() {
    final quests = state.value;
    if (quests == null) return;
    NotificationService.instance.scheduleTodayReminderIfNeeded(
      quests.where((q) => q.depth == 4).toList(),
    );
  }
}

final questRepositoryProvider = Provider<QuestRepository>((ref) {
  return QuestRepositoryImpl();
});

final questListProvider = StateNotifierProvider.family<QuestListNotifier,
    AsyncValue<List<Quest>>, String>((ref, goalId) {
  final repository = ref.watch(questRepositoryProvider);
  final notifier = QuestListNotifier(repository, ref);
  notifier.fetchQuests(goalId);
  return notifier;
});
