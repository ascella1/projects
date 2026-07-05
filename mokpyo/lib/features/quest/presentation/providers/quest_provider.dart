import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/quest_entity.dart';
import '../../domain/repositories/quest_repository.dart';
import 'user_provider.dart';
import '../../../../core/services/openai_service.dart';

// QuestListNotifier: 퀘스트 목록의 비동기 상태를 관리합니다.
class QuestListNotifier extends StateNotifier<AsyncValue<List<Quest>>> {
  final QuestRepository _repository;
  final Ref _ref;

  QuestListNotifier(this._repository, this._ref) : super(const AsyncValue.loading());

  Future<void> fetchQuests(String goalId) async {
    try {
      state = const AsyncValue.loading();
      final quests = await _repository.getQuests(goalId);
      state = AsyncValue.data(quests);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeQuest(String questId) async {
    final currentQuests = state.value ?? [];
    try {
      final quest = currentQuests.firstWhere((q) => q.id == questId);
      await _repository.completeQuest(questId);
      
      state = AsyncValue.data(
        currentQuests.map((q) => q.id == questId 
          ? q.copyWith(status: QuestStatus.completed, completedAt: DateTime.now()) 
          : q
        ).toList(),
      );

      // 유저 보상 연동 (경험치 추가 및 랜덤상자 1개 지급)
      await _ref.read(userProvider.notifier).addExp(quest.rewardExp);
      await _ref.read(userProvider.notifier).gainBox(1);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> failQuest(String questId) async {
    final currentQuests = state.value ?? [];
    try {
      await _repository.failQuest(questId);
      state = AsyncValue.data(
        currentQuests.map((q) => q.id == questId 
          ? q.copyWith(status: QuestStatus.failed) 
          : q
        ).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // AI 퀘스트 트리 생성 또는 로컬 Mock 생성
  Future<List<String>> generateAndSaveQuests({
    required String goal,
    required String characterType,
  }) async {
    state = const AsyncValue.loading();
    const goalId = 'g_active';

    // 1. 키워드 분석을 통해 추천 능력치 설정 (Fallback 규칙)
    List<String> stats = ['career'];
    final normalized = goal.toLowerCase();
    if (normalized.contains('공부') || normalized.contains('책') || normalized.contains('학습') || normalized.contains('개발') || normalized.contains('코딩') || normalized.contains('독서')) {
      stats = ['knowledge', 'career'];
    } else if (normalized.contains('운동') || normalized.contains('다이어트') || normalized.contains('헬스') || normalized.contains('건강') || normalized.contains('러닝')) {
      stats = ['health'];
    } else if (normalized.contains('돈') || normalized.contains('주식') || normalized.contains('저축') || normalized.contains('적금') || normalized.contains('부자')) {
      stats = ['money'];
    } else if (normalized.contains('친구') || normalized.contains('가족') || normalized.contains('발표') || normalized.contains('대화') || normalized.contains('스피치')) {
      stats = ['communication'];
    }

    List<Quest> questsToCreate = [];

    try {
      // 2. OpenAI API 호출 시도
      const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
      if (apiKey.isNotEmpty) {
        final service = OpenAIService(apiKey);
        final tree = await service.generateQuestTree(
          goal: goal,
          job: '일반인',
          level: '초보자',
          duration: '30일',
          weeklyHours: 10,
        );
        
        final questsListJson = tree['quests'] as List<dynamic>? ?? [];
        int index = 0;
        for (var q in questsListJson) {
          final title = q['title'] ?? '퀘스트';
          final depth = q['depth'] as int? ?? 4;
          final diffStr = q['difficulty'] as String? ?? 'easy';
          final rewardExp = q['rewardExp'] as int? ?? 10;
          final rewardStats = List<String>.from(q['rewardStats'] ?? stats);
          
          QuestDifficulty diff = QuestDifficulty.easy;
          if (diffStr == 'medium') diff = QuestDifficulty.medium;
          if (diffStr == 'hard') diff = QuestDifficulty.hard;

          questsToCreate.add(Quest(
            id: 'q_${goalId}_$index',
            goalId: goalId,
            title: title,
            depth: depth,
            status: QuestStatus.todo,
            difficulty: diff,
            rewardExp: rewardExp,
            rewardStats: rewardStats,
            dueDate: DateTime.now().add(Duration(days: depth == 1 ? 30 : (depth == 2 ? 15 : (depth == 3 ? 7 : 1)))),
          ));
          index++;
        }
      }
    } catch (_) {
      // API 에러 또는 API 키 미입력 시 Fallback Mock 데이터 생성
    }

    if (questsToCreate.isEmpty) {
      final normalized = goal.toLowerCase();
      
      if (normalized.contains('다이어트') || normalized.contains('체중') || normalized.contains('감량') || normalized.contains('살') || normalized.contains('운동') || normalized.contains('헬스') || normalized.contains('건강') || normalized.contains('러닝')) {
        // 다이어트 / 건강 테마
        questsToCreate = [
          Quest(
            id: 'q_${goalId}_1',
            goalId: goalId,
            title: '🏆 대목표: 건강하게 가벼워진 몸 가꾸기 ($goal)',
            depth: 1,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.hard,
            rewardExp: 100,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 30)),
          ),
          Quest(
            id: 'q_${goalId}_2',
            goalId: goalId,
            title: '🥈 중목표: 하루 물 2L 채우기와 식습관 조절하기',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 15)),
          ),
          Quest(
            id: 'q_${goalId}_3',
            goalId: goalId,
            title: '🥈 중목표: 규칙적인 활동량 유지 및 운동하기',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 20)),
          ),
          Quest(
            id: 'q_${goalId}_4',
            goalId: goalId,
            title: '🥉 소목표: 매끼 채소 섭취 및 간식 멀리하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 7)),
          ),
          Quest(
            id: 'q_${goalId}_5',
            goalId: goalId,
            title: '🥉 소목표: 저녁 식사 후 30분 유산소 운동하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 10)),
          ),
          Quest(
            id: 'q_${goalId}_6',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 아침 미온수 한 컵 마시기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_7',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 건강한 3식 기록 & 물 많이 마시기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_8',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 가벼운 홈트레이닝/산책으로 운동하기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
        ];
      } else if (normalized.contains('공부') || normalized.contains('학습') || normalized.contains('시험') || normalized.contains('영어') || normalized.contains('책') || normalized.contains('독서') || normalized.contains('개발') || normalized.contains('코딩') || normalized.contains('플러터') || normalized.contains('프로그래밍')) {
        // 학습 / 개발 테마
        questsToCreate = [
          Quest(
            id: 'q_${goalId}_1',
            goalId: goalId,
            title: '🏆 대목표: 지식의 정원 무성하게 가꾸기 ($goal)',
            depth: 1,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.hard,
            rewardExp: 100,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 30)),
          ),
          Quest(
            id: 'q_${goalId}_2',
            goalId: goalId,
            title: '🥈 중목표: 매일 깊이 몰입하는 자습 시간 확보',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 15)),
          ),
          Quest(
            id: 'q_${goalId}_3',
            goalId: goalId,
            title: '🥈 중목표: 학습 내용 정리 및 실습 적용',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 20)),
          ),
          Quest(
            id: 'q_${goalId}_4',
            goalId: goalId,
            title: '🥉 소목표: 이론 개념 하루 1챕터 정독하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 7)),
          ),
          Quest(
            id: 'q_${goalId}_5',
            goalId: goalId,
            title: '🥉 소목표: 직접 작은 예제 구현 및 정리하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 10)),
          ),
          Quest(
            id: 'q_${goalId}_6',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 관련 도서/강의 1챕터 학습하기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_7',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 유용한 지식 정리/코드 작성하기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_8',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 오늘 공부한 내용 핵심 3줄 요약하기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
        ];
      } else if (normalized.contains('돈') || normalized.contains('주식') || normalized.contains('저축') || normalized.contains('적금') || normalized.contains('부자') || normalized.contains('지출')) {
        // 자산 / 금융 테마
        questsToCreate = [
          Quest(
            id: 'q_${goalId}_1',
            goalId: goalId,
            title: '🏆 대목표: 미래를 지탱할 단단한 저수지 형성 ($goal)',
            depth: 1,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.hard,
            rewardExp: 100,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 30)),
          ),
          Quest(
            id: 'q_${goalId}_2',
            goalId: goalId,
            title: '🥈 중목표: 불필요한 소비 통제 및 고정 지출 리서치',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 15)),
          ),
          Quest(
            id: 'q_${goalId}_3',
            goalId: goalId,
            title: '🥈 중목표: 올바른 재테크 학습 및 투자 다변화',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 20)),
          ),
          Quest(
            id: 'q_${goalId}_4',
            goalId: goalId,
            title: '🥉 소목표: 가계부 매일 기록 루틴 완벽 정착하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 7)),
          ),
          Quest(
            id: 'q_${goalId}_5',
            goalId: goalId,
            title: '🥉 소목표: 주 1회 강제 ‘무지출 데이’ 실천하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 10)),
          ),
          Quest(
            id: 'q_${goalId}_6',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 오늘 일어난 모든 지출 투명하게 기록하기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_7',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 소비 직전 "이게 정말 필요한가?" 3초 성찰하기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_8',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 금융/경제 헤드라인 3개 이상 읽기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
        ];
      } else if (normalized.contains('친구') || normalized.contains('가족') || normalized.contains('소통') || normalized.contains('발표') || normalized.contains('대화') || normalized.contains('인간관계')) {
        // 대인관계 / 소통 테마
        questsToCreate = [
          Quest(
            id: 'q_${goalId}_1',
            goalId: goalId,
            title: '🏆 대목표: 서로 따뜻하게 이해하는 소통 정원 ($goal)',
            depth: 1,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.hard,
            rewardExp: 100,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 30)),
          ),
          Quest(
            id: 'q_${goalId}_2',
            goalId: goalId,
            title: '🥈 중목표: 타인의 목소리 경청 및 내 감정 다스리기',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 15)),
          ),
          Quest(
            id: 'q_${goalId}_3',
            goalId: goalId,
            title: '🥈 중목표: 소중한 사람들과 지속적 교감 형성하기',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 20)),
          ),
          Quest(
            id: 'q_${goalId}_4',
            goalId: goalId,
            title: '🥉 소목표: 주 1회 지인/가족에게 안부 연락하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 7)),
          ),
          Quest(
            id: 'q_${goalId}_5',
            goalId: goalId,
            title: '🥉 소목표: 부정적 생각에 휩쓸리지 않도록 마음 정돈하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 10)),
          ),
          Quest(
            id: 'q_${goalId}_6',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 대화 시 상대방 눈을 다정히 마주하기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_7',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 오늘 고마웠던 사람에게 따뜻한 메시지 1통 보내기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_8',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 하루를 마무리하며 감사한 일 3가지 꼽아보기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
        ];
      } else {
        // 기본 목표 테마
        questsToCreate = [
          Quest(
            id: 'q_${goalId}_1',
            goalId: goalId,
            title: '🏆 대목표: 내 삶을 가꾸고 윤택하게 만들 실천 ($goal)',
            depth: 1,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.hard,
            rewardExp: 100,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 30)),
          ),
          Quest(
            id: 'q_${goalId}_2',
            goalId: goalId,
            title: '🥈 중목표: 튼튼한 기초 실천 계획 세우고 행동하기',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 15)),
          ),
          Quest(
            id: 'q_${goalId}_3',
            goalId: goalId,
            title: '🥈 중목표: 방해 습관 차단 및 정적 루틴 만들기',
            depth: 2,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.medium,
            rewardExp: 50,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 20)),
          ),
          Quest(
            id: 'q_${goalId}_4',
            goalId: goalId,
            title: '🥉 소목표: 하루 15분 이상 온전히 목표에 할애하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 7)),
          ),
          Quest(
            id: 'q_${goalId}_5',
            goalId: goalId,
            title: '🥉 소목표: 성취 일기 작성을 통해 자기 반성하기',
            depth: 3,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 30,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 10)),
          ),
          Quest(
            id: 'q_${goalId}_6',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 오늘 실천을 방해하는 습관 1가지 멀리하기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_7',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 집중 타이머 키고 15분 실행해보기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          Quest(
            id: 'q_${goalId}_8',
            goalId: goalId,
            title: '🌱 일일 퀘스트: 스스로를 가꾸는 행동 1가지 기록하고 칭찬하기',
            depth: 4,
            status: QuestStatus.todo,
            difficulty: QuestDifficulty.easy,
            rewardExp: 10,
            rewardStats: stats,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
        ];
      }
    }

    await _repository.createQuests(questsToCreate);
    state = AsyncValue.data(questsToCreate);
    return stats;
  }
}

// Repository Provider 정의
final questRepositoryProvider = Provider<QuestRepository>((ref) {
  throw UnimplementedError('questRepositoryProvider must be overridden in main.dart');
});

// Quest Provider 정의
final questListProvider = StateNotifierProvider.family<QuestListNotifier, AsyncValue<List<Quest>>, String>((ref, goalId) {
  final repository = ref.watch(questRepositoryProvider);
  final notifier = QuestListNotifier(repository, ref);
  notifier.fetchQuests(goalId);
  return notifier;
});
