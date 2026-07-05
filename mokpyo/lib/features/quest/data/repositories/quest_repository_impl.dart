import '../../domain/entities/quest_entity.dart';
import '../../domain/repositories/quest_repository.dart';

class QuestRepositoryImpl implements QuestRepository {
  // 실제 프로덕션에서는 Firestore 인스턴스나 Local Hive DB에 의존성을 가집니다.
  final List<Quest> _mockQuests = [];

  QuestRepositoryImpl() {
    // 뼈대 검증을 위한 가상 데이터 초기화
    _mockQuests.addAll([
      Quest(
        id: 'q_1',
        goalId: 'g_1',
        title: '대목표: 10억 모으기 설계',
        depth: 1,
        status: QuestStatus.todo,
        difficulty: QuestDifficulty.hard,
        rewardExp: 100,
        rewardStats: const ['money'],
        dueDate: DateTime.now().add(const Duration(days: 365)),
      ),
      Quest(
        id: 'q_2',
        goalId: 'g_1',
        title: '중목표: Flutter 개발 공부하기',
        depth: 2,
        status: QuestStatus.todo,
        difficulty: QuestDifficulty.medium,
        rewardExp: 50,
        rewardStats: const ['knowledge', 'career'],
        dueDate: DateTime.now().add(const Duration(days: 30)),
      ),
      Quest(
        id: 'q_3',
        goalId: 'g_1',
        title: '일일 퀘스트: 플러터 위젯 북스 스크랩',
        depth: 4,
        status: QuestStatus.todo,
        difficulty: QuestDifficulty.easy,
        rewardExp: 10,
        rewardStats: const ['knowledge'],
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
    ]);
  }

  @override
  Future<List<Quest>> getQuests(String goalId) async {
    // 특정 goalId 에 해당하는 퀘스트 목록 필터링 반환
    await Future.delayed(const Duration(milliseconds: 500)); // API 통신 가상 지연
    return _mockQuests.where((q) => q.goalId == goalId).toList();
  }

  @override
  Future<void> createQuests(List<Quest> quests) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (quests.isNotEmpty) {
      final targetGoalId = quests.first.goalId;
      _mockQuests.removeWhere((q) => q.goalId == targetGoalId);
    }
    _mockQuests.addAll(quests);
  }

  @override
  Future<void> completeQuest(String questId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockQuests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _mockQuests[index] = _mockQuests[index].copyWith(
        status: QuestStatus.completed,
        completedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> failQuest(String questId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockQuests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _mockQuests[index] = _mockQuests[index].copyWith(
        status: QuestStatus.failed,
      );
    }
  }

  @override
  Future<void> updateQuestDifficulty(String questId, QuestDifficulty newDifficulty) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockQuests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _mockQuests[index] = _mockQuests[index].copyWith(
        difficulty: newDifficulty,
      );
    }
  }
}
