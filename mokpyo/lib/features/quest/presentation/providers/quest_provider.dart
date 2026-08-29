import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/quest_entity.dart';
import '../../domain/repositories/quest_repository.dart';
import '../../data/repositories/quest_repository_impl.dart';
import 'user_provider.dart';
import '../../../../core/services/claude_ai_service.dart';
import '../../../../core/services/google_ai_service.dart';
import '../../../../core/services/openai_service.dart';
import '../../../../core/services/template_service.dart';
import '../../../../core/config/api_config.dart';

class QuestGenerationResult {
  final List<String> stats;
  final List<Quest> quests;
  final String? aiError;

  const QuestGenerationResult(
      {required this.stats, required this.quests, this.aiError});
}

class QuestListNotifier
    extends StateNotifier<AsyncValue<List<Quest>>> {
  final QuestRepository _repository;
  final Ref _ref;

  QuestListNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading());

  Future<void> fetchQuests(String goalId) async {
    try {
      state = const AsyncValue.loading();
      final quests = await _repository.getQuests(goalId);
      state = AsyncValue.data(quests);
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 편집된 퀘스트 목록으로 교체 저장 (온보딩 미리보기 수정 반영용)
  Future<void> replaceQuests(List<Quest> quests) async {
    await _repository.createQuests(quests);
    state = AsyncValue.data(quests);
  }

  // AI 퀘스트 트리 생성. 반환값: 추천 능력치 목록 + 생성된 퀘스트 목록
  Future<QuestGenerationResult> generateAndSaveQuests({
    required String goal,
    required String characterType,
  }) async {
    state = const AsyncValue.loading();
    const goalId = 'g_active';

    // 흔한 목표(mokpyo_templates.json 키워드 매칭)는 AI 호출 없이 바로 템플릿 퀘스트를 사용한다
    try {
      final templateMatch = await TemplateService.matchGoal(goal, goalId);
      if (templateMatch != null) {
        await _repository.createQuests(templateMatch.quests);
        state = AsyncValue.data(templateMatch.quests);
        return QuestGenerationResult(
            stats: templateMatch.stats, quests: templateMatch.quests);
      }
    } catch (e) {
      // 템플릿 파일 로드/파싱 실패 시에는 AI 생성 경로로 계속 진행한다
      debugPrint('템플릿 매칭 실패, AI 생성으로 진행: $e');
    }

    // 키워드 기반 능력치 추천 (AI 실패 시 Fallback)
    List<String> stats = ['career'];
    final normalized = goal.toLowerCase();
    if (normalized.contains('공부') ||
        normalized.contains('책') ||
        normalized.contains('학습') ||
        normalized.contains('개발') ||
        normalized.contains('코딩') ||
        normalized.contains('독서')) {
      stats = ['knowledge', 'career'];
    } else if (normalized.contains('운동') ||
        normalized.contains('다이어트') ||
        normalized.contains('헬스') ||
        normalized.contains('건강') ||
        normalized.contains('러닝')) {
      stats = ['health'];
    } else if (normalized.contains('돈') ||
        normalized.contains('주식') ||
        normalized.contains('저축') ||
        normalized.contains('적금') ||
        normalized.contains('부자') ||
        normalized.contains('억')) {
      stats = ['money'];
    } else if (normalized.contains('친구') ||
        normalized.contains('가족') ||
        normalized.contains('발표') ||
        normalized.contains('대화') ||
        normalized.contains('스피치')) {
      stats = ['communication'];
    }

    List<Quest> questsToCreate = [];
    String? aiError;

    // Claude 우선 시도 → Gemini → OpenAI
    final useClaude = claudeApiKey.isNotEmpty &&
        !claudeApiKey.startsWith('YOUR_');
    final useGemini = geminiApiKey.isNotEmpty &&
        !geminiApiKey.startsWith('YOUR_');
    final useOpenAI = openAiApiKey.isNotEmpty &&
        !openAiApiKey.startsWith('YOUR_');

    if (useClaude || useGemini || useOpenAI) {
      try {
        Map<String, dynamic> tree;
        if (useClaude) {
          final service = ClaudeAIService(claudeApiKey);
          tree = await service.generateQuestTree(
            goal: goal,
            job: '일반인',
            level: '초보자',
            duration: '30일',
            weeklyHours: 10,
          );
        } else if (useGemini) {
          final service = GoogleAIService(geminiApiKey);
          tree = await service.generateQuestTree(
            goal: goal,
            job: '일반인',
            level: '초보자',
            duration: '30일',
            weeklyHours: 10,
          );
        } else {
          final service = OpenAIService(openAiApiKey);
          tree = await service.generateQuestTree(
            goal: goal,
            job: '일반인',
            level: '초보자',
            duration: '30일',
            weeklyHours: 10,
          );
        }

        final questsListJson = tree['quests'] as List<dynamic>? ?? [];
        // AI가 추천한 능력치로 업데이트
        if (questsListJson.isNotEmpty) {
          final firstStats = questsListJson.first['rewardStats'];
          if (firstStats is List && firstStats.isNotEmpty) {
            stats = List<String>.from(firstStats);
          }
        }

        int index = 0;
        for (var q in questsListJson) {
          final title = q['title'] as String? ?? '퀘스트';
          final depth = q['depth'] as int? ?? 4;
          final diffStr = q['difficulty'] as String? ?? 'easy';
          final rewardExp = q['rewardExp'] as int? ?? 10;
          final rewardStats =
              List<String>.from(q['rewardStats'] as List? ?? stats);

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
            dueDate: DateTime.now().add(Duration(
                days: depth == 1
                    ? 30
                    : depth == 2
                        ? 15
                        : depth == 3
                            ? 7
                            : 1)),
          ));
          index++;
        }
      } catch (e) {
        // API 오류 시 Fallback으로 진행하되 원인은 기록해 UI에 노출한다
        debugPrint('AI 퀘스트 생성 실패, 기본 퀘스트로 대체: $e');
        aiError = e.toString();
        questsToCreate = [];
      }
    }

    if (questsToCreate.isEmpty) {
      questsToCreate = _buildFallbackQuests(goal, goalId, stats);
    }

    await _repository.createQuests(questsToCreate);
    state = AsyncValue.data(questsToCreate);
    return QuestGenerationResult(
        stats: stats, quests: questsToCreate, aiError: aiError);
  }

  List<Quest> _buildFallbackQuests(
      String goal, String goalId, List<String> stats) {
    final normalized = goal.toLowerCase();

    if (normalized.contains('다이어트') ||
        normalized.contains('체중') ||
        normalized.contains('감량') ||
        normalized.contains('살') ||
        normalized.contains('운동') ||
        normalized.contains('헬스') ||
        normalized.contains('건강') ||
        normalized.contains('러닝')) {
      return _healthQuests(goal, goalId, stats);
    } else if (normalized.contains('공부') ||
        normalized.contains('학습') ||
        normalized.contains('시험') ||
        normalized.contains('영어') ||
        normalized.contains('책') ||
        normalized.contains('독서') ||
        normalized.contains('개발') ||
        normalized.contains('코딩') ||
        normalized.contains('플러터') ||
        normalized.contains('프로그래밍')) {
      return _studyQuests(goal, goalId, stats);
    } else if (normalized.contains('돈') ||
        normalized.contains('주식') ||
        normalized.contains('저축') ||
        normalized.contains('적금') ||
        normalized.contains('부자') ||
        normalized.contains('억') ||
        normalized.contains('지출')) {
      return _moneyQuests(goal, goalId, stats);
    } else if (normalized.contains('친구') ||
        normalized.contains('가족') ||
        normalized.contains('소통') ||
        normalized.contains('발표') ||
        normalized.contains('대화') ||
        normalized.contains('인간관계')) {
      return _socialQuests(goal, goalId, stats);
    }
    return _defaultQuests(goal, goalId, stats);
  }

  List<Quest> _healthQuests(
      String goal, String goalId, List<String> stats) => [
        _q(goalId, 1, '🏆 대목표: 건강하게 가벼워진 몸 가꾸기 ($goal)',
            QuestDifficulty.hard, 100, stats, 30),
        _q(goalId, 2, '🥈 중목표: 하루 물 2L 채우기와 식습관 조절하기',
            QuestDifficulty.medium, 50, stats, 15),
        _q(goalId, 2, '🥈 중목표: 규칙적인 활동량 유지 및 운동하기',
            QuestDifficulty.medium, 50, stats, 20),
        _q(goalId, 3, '🥉 소목표: 매끼 채소 섭취 및 간식 멀리하기',
            QuestDifficulty.easy, 30, stats, 7),
        _q(goalId, 3, '🥉 소목표: 저녁 식사 후 30분 유산소 운동하기',
            QuestDifficulty.easy, 30, stats, 10),
        _q(goalId, 4, '🌱 일일 퀘스트: 아침 미온수 한 컵 마시기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 건강한 3식 기록 & 물 많이 마시기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 가벼운 홈트레이닝/산책으로 운동하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 물 500ml 추가로 마시기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 5분 스트레칭으로 몸 풀기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 엘리베이터 대신 계단 이용하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 야식 참고 일찍 잠자리에 들기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 앉은 자리에서 목/어깨 스트레칭 10회',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 하루 8000보 걷기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 튀김/과자 대신 견과류 간식 먹기',
            QuestDifficulty.easy, 10, stats, 1),
      ];

  List<Quest> _studyQuests(
      String goal, String goalId, List<String> stats) => [
        _q(goalId, 1, '🏆 대목표: 지식의 정원 무성하게 가꾸기 ($goal)',
            QuestDifficulty.hard, 100, stats, 30),
        _q(goalId, 2, '🥈 중목표: 매일 깊이 몰입하는 자습 시간 확보',
            QuestDifficulty.medium, 50, stats, 15),
        _q(goalId, 2, '🥈 중목표: 학습 내용 정리 및 실습 적용',
            QuestDifficulty.medium, 50, stats, 20),
        _q(goalId, 3, '🥉 소목표: 이론 개념 하루 1챕터 정독하기',
            QuestDifficulty.easy, 30, stats, 7),
        _q(goalId, 3, '🥉 소목표: 직접 작은 예제 구현 및 정리하기',
            QuestDifficulty.easy, 30, stats, 10),
        _q(goalId, 4, '🌱 일일 퀘스트: 관련 도서/강의 1챕터 학습하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 유용한 지식 정리/코드 작성하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 오늘 공부한 내용 핵심 3줄 요약하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 단어/개념 5개 암기하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 25분 집중 타이머(뽀모도로) 1세트 돌리기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 어제 배운 내용 복습 10분',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 관련 아티클/블로그 1편 읽기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 오답노트/에러노트 1건 작성하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 공부 시작 전 오늘의 학습 목표 적어보기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: SNS/유튜브 없이 순수 집중 30분 확보하기',
            QuestDifficulty.easy, 10, stats, 1),
      ];

  List<Quest> _moneyQuests(
      String goal, String goalId, List<String> stats) => [
        _q(goalId, 1, '🏆 대목표: 미래를 지탱할 단단한 자산 형성 ($goal)',
            QuestDifficulty.hard, 100, stats, 30),
        _q(goalId, 2, '🥈 중목표: 불필요한 소비 통제 및 고정 지출 리서치',
            QuestDifficulty.medium, 50, stats, 15),
        _q(goalId, 2, '🥈 중목표: 올바른 재테크 학습 및 투자 다변화',
            QuestDifficulty.medium, 50, stats, 20),
        _q(goalId, 3, '🥉 소목표: 가계부 매일 기록 루틴 완벽 정착하기',
            QuestDifficulty.easy, 30, stats, 7),
        _q(goalId, 3, '🥉 소목표: 주 1회 강제 무지출 데이 실천하기',
            QuestDifficulty.easy, 30, stats, 10),
        _q(goalId, 4, '🌱 일일 퀘스트: 오늘 발생한 모든 지출 기록하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 소비 전 "이게 정말 필요한가?" 3초 성찰하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 금융/경제 헤드라인 3개 읽기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 커피/배달 대신 집밥 챙겨먹기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 오늘 사용한 구독 서비스 점검하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 잔돈이라도 저금통에 저축하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 중고거래 앱에서 안 쓰는 물건 1개 정리하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 오늘 지출 목표 금액 미리 정해두기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 통장/카드 잔액 확인하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 투자/재테크 뉴스레터 1편 읽기',
            QuestDifficulty.easy, 10, stats, 1),
      ];

  List<Quest> _socialQuests(
      String goal, String goalId, List<String> stats) => [
        _q(goalId, 1, '🏆 대목표: 서로 따뜻하게 이해하는 소통 정원 ($goal)',
            QuestDifficulty.hard, 100, stats, 30),
        _q(goalId, 2, '🥈 중목표: 타인의 목소리 경청 및 내 감정 다스리기',
            QuestDifficulty.medium, 50, stats, 15),
        _q(goalId, 2, '🥈 중목표: 소중한 사람들과 지속적 교감 형성하기',
            QuestDifficulty.medium, 50, stats, 20),
        _q(goalId, 3, '🥉 소목표: 주 1회 지인/가족에게 안부 연락하기',
            QuestDifficulty.easy, 30, stats, 7),
        _q(goalId, 3, '🥉 소목표: 부정적 생각에 휩쓸리지 않도록 마음 정돈하기',
            QuestDifficulty.easy, 30, stats, 10),
        _q(goalId, 4, '🌱 일일 퀘스트: 대화 시 상대방 눈을 다정히 마주하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 오늘 고마웠던 사람에게 따뜻한 메시지 1통 보내기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 하루를 마무리하며 감사한 일 3가지 꼽아보기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 오늘 만난 사람에게 먼저 인사 건네기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 대화 중 상대방 말 끝까지 경청하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 오늘 있었던 일 가족/친구와 나누기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 칭찬 한마디 건네기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 부정적인 말 대신 긍정적으로 표현해보기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: SNS 대신 직접 통화로 안부 묻기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 하루 5분 명상으로 마음 다스리기',
            QuestDifficulty.easy, 10, stats, 1),
      ];

  List<Quest> _defaultQuests(
      String goal, String goalId, List<String> stats) => [
        _q(goalId, 1, '🏆 대목표: 내 삶을 가꾸고 윤택하게 만들 실천 ($goal)',
            QuestDifficulty.hard, 100, stats, 30),
        _q(goalId, 2, '🥈 중목표: 튼튼한 기초 실천 계획 세우고 행동하기',
            QuestDifficulty.medium, 50, stats, 15),
        _q(goalId, 2, '🥈 중목표: 방해 습관 차단 및 정적 루틴 만들기',
            QuestDifficulty.medium, 50, stats, 20),
        _q(goalId, 3, '🥉 소목표: 하루 15분 이상 온전히 목표에 할애하기',
            QuestDifficulty.easy, 30, stats, 7),
        _q(goalId, 3, '🥉 소목표: 성취 일기 작성을 통해 자기 반성하기',
            QuestDifficulty.easy, 30, stats, 10),
        _q(goalId, 4, '🌱 일일 퀘스트: 오늘 실천을 방해하는 습관 1가지 멀리하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 집중 타이머 켜고 15분 실행해보기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 스스로를 가꾸는 행동 1가지 기록하고 칭찬하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 오늘의 목표를 아침에 3줄로 적어보기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 잠들기 전 오늘 실천 여부 체크하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 방해되는 알림 30분간 꺼두기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 목표와 관련된 작은 행동 1가지 실천하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 어제보다 5분 더 목표에 투자하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 실천 일지에 오늘의 기분 기록하기',
            QuestDifficulty.easy, 10, stats, 1),
        _q(goalId, 4, '🌱 일일 퀘스트: 목표를 이룬 미래의 나를 상상해보기',
            QuestDifficulty.easy, 10, stats, 1),
      ];

  static int _questIndex = 0;

  Quest _q(
    String goalId,
    int depth,
    String title,
    QuestDifficulty diff,
    int exp,
    List<String> stats,
    int dueDays,
  ) {
    return Quest(
      id: 'q_${goalId}_${_questIndex++}',
      goalId: goalId,
      title: title,
      depth: depth,
      status: QuestStatus.todo,
      difficulty: diff,
      rewardExp: exp,
      rewardStats: stats,
      dueDate: DateTime.now().add(Duration(days: dueDays)),
    );
  }
}

// QuestRepository는 기본 구현체를 직접 제공합니다.
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
