import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/services/level_config_service.dart';
import '../../../quest/domain/entities/quest_entity.dart';
import '../../../quest/presentation/providers/quest_provider.dart';
import '../../../quest/presentation/providers/user_provider.dart';

// 목표 입력 위저드 단계. 캐릭터 선택 → 대목표 → 스탯 선택 → 중목표 →
// 소목표 → 일일퀘스트 → 최종 확인, 총 7단계(0~6).
class GoalWizardState {
  final int step;
  final String characterType;
  final String mainGoalTitle;
  final List<String> selectedStats;
  final List<String> midGoals;
  final List<String> subGoals;
  final List<String> dailyQuests;

  const GoalWizardState({
    this.step = 0,
    this.characterType = 'fox',
    this.mainGoalTitle = '',
    this.selectedStats = const [],
    this.midGoals = const [],
    this.subGoals = const [],
    this.dailyQuests = const [],
  });

  GoalWizardState copyWith({
    int? step,
    String? characterType,
    String? mainGoalTitle,
    List<String>? selectedStats,
    List<String>? midGoals,
    List<String>? subGoals,
    List<String>? dailyQuests,
  }) {
    return GoalWizardState(
      step: step ?? this.step,
      characterType: characterType ?? this.characterType,
      mainGoalTitle: mainGoalTitle ?? this.mainGoalTitle,
      selectedStats: selectedStats ?? this.selectedStats,
      midGoals: midGoals ?? this.midGoals,
      subGoals: subGoals ?? this.subGoals,
      dailyQuests: dailyQuests ?? this.dailyQuests,
    );
  }
}

class GoalWizardNotifier extends StateNotifier<GoalWizardState> {
  GoalWizardNotifier() : super(const GoalWizardState());

  void setCharacter(String type) =>
      state = state.copyWith(characterType: type);

  void setMainGoal(String title) =>
      state = state.copyWith(mainGoalTitle: title);

  void toggleStat(String stat) {
    final stats = List<String>.from(state.selectedStats);
    if (stats.contains(stat)) {
      stats.remove(stat);
    } else {
      stats.add(stat);
    }
    state = state.copyWith(selectedStats: stats);
  }

  // 각 동적 목록 단계(중목표/소목표/일일퀘스트)는 화면에서 로컬
  // TextEditingController 리스트로 편집되다가, 다음 단계로 넘어갈 때
  // 한 번에 커밋된다 (기존 mokpyo의 _dailyControllers 패턴과 동일).
  void setMidGoals(List<String> goals) =>
      state = state.copyWith(midGoals: goals);
  void setSubGoals(List<String> goals) =>
      state = state.copyWith(subGoals: goals);
  void setDailyQuests(List<String> quests) =>
      state = state.copyWith(dailyQuests: quests);

  void goToStep(int step) => state = state.copyWith(step: step);
  void nextStep() => state = state.copyWith(step: state.step + 1);
  void prevStep() => state = state.copyWith(step: state.step - 1);

  void reset() => state = const GoalWizardState();

  // 위저드에서 입력한 내용으로 depth 1~4 Quest들을 만들어 저장하고
  // 온보딩을 완료 처리한다. (ConsumerState의 WidgetRef에서 호출되므로
  // riverpod 3에서 별개 타입인 Ref가 아니라 WidgetRef를 받는다)
  Future<void> submit(WidgetRef ref) async {
    const goalId = 'g_active';
    final cfg = LevelConfigService.current;
    int seq = 0;

    Quest build(int depth, String title, int dueDays) {
      return Quest(
        id: 'q_${goalId}_${depth}_${seq++}',
        goalId: goalId,
        title: title,
        depth: depth,
        status: QuestStatus.todo,
        difficulty: depth == 1
            ? QuestDifficulty.hard
            : depth == 4
                ? QuestDifficulty.easy
                : QuestDifficulty.medium,
        rewardExp: cfg.rewardExpByDepth[depth] ?? 10,
        rewardStats: state.selectedStats,
        dueDate: DateTime.now().add(Duration(days: dueDays)),
      );
    }

    final quests = <Quest>[
      build(1, state.mainGoalTitle.trim(), 30),
      ...state.midGoals
          .where((t) => t.trim().isNotEmpty)
          .map((t) => build(2, t.trim(), 15)),
      ...state.subGoals
          .where((t) => t.trim().isNotEmpty)
          .map((t) => build(3, t.trim(), 7)),
      ...state.dailyQuests
          .where((t) => t.trim().isNotEmpty)
          .map((t) => build(4, t.trim(), 1)),
    ];

    await ref.read(questListProvider(goalId).notifier).replaceQuests(quests);
    await ref.read(userProvider.notifier).completeOnboarding(
          characterType: state.characterType,
          goal: state.mainGoalTitle.trim(),
          recommendedStats: state.selectedStats,
        );
    reset();
  }
}

final goalWizardProvider =
    StateNotifierProvider<GoalWizardNotifier, GoalWizardState>((ref) {
  return GoalWizardNotifier();
});
