import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/character_util.dart';
import '../../../../core/utils/stat_util.dart';
import '../providers/goal_wizard_provider.dart';
import '../utils/wizard_reactions.dart';

// AI 없이 사용자가 직접 목표를 입력하는 7단계 위저드.
// 0:캐릭터선택 1:대목표 2:스탯선택 3:중목표 4:소목표 5:일일퀘스트 6:최종확인
class GoalWizardScreen extends ConsumerStatefulWidget {
  const GoalWizardScreen({super.key});

  @override
  ConsumerState<GoalWizardScreen> createState() => _GoalWizardScreenState();
}

class _GoalWizardScreenState extends ConsumerState<GoalWizardScreen> {
  final TextEditingController _mainGoalController = TextEditingController();
  final List<TextEditingController> _midControllers = [];
  final List<TextEditingController> _subControllers = [];
  final List<TextEditingController> _dailyControllers = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _mainGoalController.dispose();
    for (final c in [..._midControllers, ..._subControllers, ..._dailyControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addController(List<TextEditingController> list) {
    setState(() => list.add(TextEditingController()));
  }

  void _removeController(List<TextEditingController> list, int index) {
    setState(() => list.removeAt(index).dispose());
  }

  List<String> _nonEmptyTexts(List<TextEditingController> list) =>
      list.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(goalWizardProvider);
    final notifier = ref.read(goalWizardProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: _isSubmitting
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _buildStep(wizardState, notifier),
        ),
      ),
    );
  }

  // 각 단계는 TextEditingController가 State 필드로 유지되므로, IndexedStack
  // 없이 현재 단계 하나만 빌드해도 입력값이 보존된다 (탭 전환으로 재빌드돼도
  // 컨트롤러 인스턴스 자체는 그대로).
  Widget _buildStep(GoalWizardState wizardState, GoalWizardNotifier notifier) {
    final reaction = reactionForStep(wizardState.step, wizardState);
    switch (wizardState.step) {
      case 0:
        return _buildCharacterStep(wizardState, notifier);
      case 1:
        return _buildMainGoalStep(notifier, wizardState, reaction);
      case 2:
        return _buildStatSelectStep(wizardState, notifier, reaction);
      case 3:
        return _buildDynamicListStep(
          title: '그 목표를 이루기 위해서\n해야하는게 뭔가요?',
          subtitle: '대목표를 이루기 위한 중간 단계 목표들을 적어주세요. (중목표)',
          hint: '예: 매일 30분 이상 운동하기',
          controllers: _midControllers,
          onBack: notifier.prevStep,
          onNext: () {
            notifier.setMidGoals(_nonEmptyTexts(_midControllers));
            notifier.nextStep();
          },
          reaction: reaction,
          characterType: wizardState.characterType,
        );
      case 4:
        return _buildDynamicListStep(
          title: '그 중목표를 이루기 위해서\n해야하는게 뭔가요?',
          subtitle: '중목표를 이루기 위한 더 구체적인 목표들을 적어주세요. (소목표)',
          hint: '예: 주 3회 헬스장 가기',
          controllers: _subControllers,
          onBack: notifier.prevStep,
          onNext: () {
            notifier.setSubGoals(_nonEmptyTexts(_subControllers));
            notifier.nextStep();
          },
          reaction: reaction,
          characterType: wizardState.characterType,
        );
      case 5:
        return _buildDynamicListStep(
          title: '매일 실천할 수 있는\n작은 행동은 뭔가요?',
          subtitle: '오늘 당장 시작할 수 있는 일일 퀘스트를 적어주세요. 최소 1개 이상 필요해요.',
          hint: '예: 물 500ml 마시기',
          controllers: _dailyControllers,
          onBack: notifier.prevStep,
          onNext: () {
            final quests = _nonEmptyTexts(_dailyControllers);
            if (quests.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일일 퀘스트를 최소 1개 이상 입력해주세요!')),
              );
              return;
            }
            notifier.setDailyQuests(quests);
            notifier.nextStep();
          },
          reaction: reaction,
          characterType: wizardState.characterType,
        );
      default:
        return _buildReviewStep(wizardState, notifier, reaction);
    }
  }

  // 캐릭터가 바로 이전 단계의 답변에 대해 보내는 한마디. 코칭을 받는 느낌을
  // 주기 위한 장치로, 각 단계 상단에 배치한다.
  Widget _coachReactionBubble(String characterType, String reaction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          characterVisual(characterType, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6)
                ],
              ),
              child: Text(
                reaction,
                style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF5D4037),
                    height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Step 0: 캐릭터 선택 --------------------

  Widget _buildCharacterStep(
      GoalWizardState state, GoalWizardNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            '반가워요! 스스로 목표를 세우고\n가꿔나가는 정원입니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            '함께할\n동물 친구를 골라주세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 28),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.25,
                children: ['cat', 'dog', 'rabbit', 'fox']
                    .map((type) => _characterCard(type, state, notifier))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: notifier.nextStep,
              child: const Text('선택 완료',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _characterCard(
      String type, GoalWizardState state, GoalWizardNotifier notifier) {
    final isSelected = state.characterType == type;
    return GestureDetector(
      onTap: () => notifier.setCharacter(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.green.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1)
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            characterVisual(type, size: 38),
            const SizedBox(height: 6),
            Text(characterLabel(type),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            if (isSelected) ...[
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('선택됨',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------- Step 1: 대목표 --------------------

  Widget _buildMainGoalStep(
      GoalWizardNotifier notifier, GoalWizardState state, String? reaction) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          if (reaction != null)
            _coachReactionBubble(state.characterType, reaction),
          const Text('🎯', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          const Text(
            '대목표는 뭔가요?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            '예: 10kg 다이어트, 플러터 앱 출시하기,\n영어 회화 마스터, 1억 모으기',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _mainGoalController,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '이루고 싶은 핵심 목표를 입력해주세요...',
            ),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: notifier.prevStep,
                  child: const Text('이전으로'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    if (_mainGoalController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('대목표를 입력해주세요!')),
                      );
                      return;
                    }
                    notifier.setMainGoal(_mainGoalController.text.trim());
                    notifier.nextStep();
                  },
                  child: const Text('다음',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- Step 2: 스탯 선택 --------------------

  Widget _buildStatSelectStep(
      GoalWizardState state, GoalWizardNotifier notifier, String? reaction) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          if (reaction != null)
            _coachReactionBubble(state.characterType, reaction),
          const Text('📊', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          const Text(
            '이 목표는 어떤 능력치와\n관련이 있나요?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            '하나 이상 선택해주세요. 퀘스트 완료 시 선택한 능력치가 성장합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: allStatKeys.map((stat) {
              final info = statInfo(stat);
              final isSelected = state.selectedStats.contains(stat);
              return GestureDetector(
                onTap: () => notifier.toggleStat(stat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? info.color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? info.color : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: Text(
                    '${info.emoji} ${info.label}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: notifier.prevStep,
                  child: const Text('이전으로'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: state.selectedStats.isEmpty
                      ? null
                      : notifier.nextStep,
                  child: const Text('다음',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- Step 3/4/5: 동적 목록 입력 --------------------

  Widget _buildDynamicListStep({
    required String title,
    required String subtitle,
    required String hint,
    required List<TextEditingController> controllers,
    required VoidCallback onBack,
    required VoidCallback onNext,
    String? reaction,
    required String characterType,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              if (reaction != null)
                _coachReactionBubble(characterType, reaction),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controllers.length,
                itemBuilder: (ctx, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers[i],
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              hintText: hint,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _removeController(controllers, i);
                            setLocalState(() {});
                          },
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _addController(controllers);
                    setLocalState(() {});
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('항목 추가'),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      child: const Text('이전으로'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onNext,
                      child: const Text('다음',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- Step 6: 최종 확인 --------------------

  Widget _buildReviewStep(
      GoalWizardState state, GoalWizardNotifier notifier, String? reaction) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          if (reaction != null)
            _coachReactionBubble(state.characterType, reaction),
          const Text('✅ 입력 완료',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text(
            '이렇게 목표를 시작할게요!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏆 대목표',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    state.mainGoalTitle,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const Divider(height: 28),
                  const Text('📊 성장할 능력치',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.selectedStats.map((stat) {
                      final info = statInfo(stat);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: info.color.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${info.emoji} ${info.label}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: info.color),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 28),
                  _reviewCountRow('🥈 중목표', state.midGoals.length),
                  const SizedBox(height: 6),
                  _reviewCountRow('🥉 소목표', state.subGoals.length),
                  const SizedBox(height: 6),
                  _reviewCountRow('🌱 일일 퀘스트', state.dailyQuests.length),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: notifier.prevStep,
                  child: const Text('이전으로'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() => _isSubmitting = true);
                    await notifier.submit(ref);
                    if (!mounted) return;
                    setState(() => _isSubmitting = false);
                  },
                  child: const Text('목표 수락 및 시작!',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewCountRow(String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        Text('$count개',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}
