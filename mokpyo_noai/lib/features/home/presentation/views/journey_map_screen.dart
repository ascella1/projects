import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/level_config_service.dart';
import '../../../quest/domain/entities/quest_entity.dart';
import '../../../quest/presentation/providers/quest_provider.dart';
import '../../../quest/presentation/providers/user_provider.dart';

const Map<int, String> _tierEmoji = {1: '🏆', 2: '🥈', 3: '🥉', 4: '🌱'};
const Map<int, String> _tierLabel = {
  1: '대목표',
  2: '중목표',
  3: '소목표',
  4: '일일 퀘스트',
};

// 목표 트리를 리스트가 아니라 "여정을 탐험하는" 느낌의 세로 타임라인으로
// 보여준다. 맨 위가 최종 목적지(🏆 대목표), 맨 아래가 오늘 당장 실천할
// 일일 퀘스트(🌱)로, 위로 올라갈수록 더 큰 목표를 향해 나아가는 구조다.
// 잠금 해제된 퀘스트는 탭해서 바로 완료할 수도 있다.
class JourneyMapScreen extends ConsumerWidget {
  const JourneyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questListProvider('g_active'));
    final userState = ref.watch(userProvider);
    final cfg = LevelConfigService.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🗺️ 여정 지도',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              SizedBox(height: 4),
              Text('맨 위 대목표를 향해 한 걸음씩 나아가는 여정을 확인해보세요.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: questsAsync.when(
            data: (quests) {
              final ordered = [
                ...quests.where((q) => q.depth == 1),
                ...quests.where((q) => q.depth == 2),
                ...quests.where((q) => q.depth == 3),
                ...quests.where((q) => q.depth == 4),
              ];

              if (ordered.isEmpty) {
                return const Center(
                  child: Text('아직 등록된 목표가 없어요.',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: ordered.length,
                itemBuilder: (ctx, i) {
                  final quest = ordered[i];
                  final requiredLevel = quest.depth == 4
                      ? 1
                      : (cfg.tierUnlockLevelByDepth[quest.depth] ?? 1);
                  final unlocked =
                      quest.depth == 4 || userState.level >= requiredLevel;
                  return _timelineNode(
                    context,
                    ref,
                    quest,
                    isFirst: i == 0,
                    isLast: i == ordered.length - 1,
                    unlocked: unlocked,
                    requiredLevel: requiredLevel,
                  );
                },
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('오류: $err')),
          ),
        ),
      ],
    );
  }

  Widget _timelineNode(
    BuildContext context,
    WidgetRef ref,
    Quest quest, {
    required bool isFirst,
    required bool isLast,
    required bool unlocked,
    required int requiredLevel,
  }) {
    final color = AppColors.depthColors[quest.depth];
    final completed = quest.status == QuestStatus.completed;
    final tierEmoji = _tierEmoji[quest.depth]!;
    final tierLabel = _tierLabel[quest.depth]!;
    final railLineColor = Colors.grey.withValues(alpha: 0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 3,
                    color: isFirst ? Colors.transparent : railLineColor,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !unlocked
                        ? Colors.grey.withValues(alpha: 0.25)
                        : (completed ? color : Colors.white),
                    border: Border.all(
                      color: !unlocked
                          ? Colors.grey.withValues(alpha: 0.4)
                          : color,
                      width: 2,
                    ),
                  ),
                  child: !unlocked
                      ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                      : completed
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : Text(tierEmoji,
                              style: const TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: Container(
                    width: 3,
                    color: isLast ? Colors.transparent : railLineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: () => _onNodeTap(
                    context, ref, quest, unlocked, completed, requiredLevel),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: !unlocked
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: color.withValues(alpha: unlocked ? 0.4 : 0.15)),
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6)
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$tierEmoji $tierLabel',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color)),
                          ),
                          const Spacer(),
                          if (!unlocked)
                            Text('Lv.$requiredLevel 해금',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          if (completed)
                            const Icon(Icons.check_circle,
                                color: AppColors.success, size: 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        quest.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: !unlocked
                              ? Colors.grey
                              : AppColors.textPrimary,
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (unlocked && !completed) ...[
                        const SizedBox(height: 4),
                        Text('탭해서 완료하기 · EXP +${quest.rewardExp}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onNodeTap(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
    bool unlocked,
    bool completed,
    int requiredLevel,
  ) async {
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lv.$requiredLevel에 해금돼요! 조금만 더 성장해봐요.')),
      );
      return;
    }
    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 완료한 퀘스트예요!')),
      );
      return;
    }

    final levelBefore = ref.read(userProvider).level;
    final levelsGained = await ref
        .read(questListProvider('g_active').notifier)
        .completeQuest(quest.id);
    if (!context.mounted) return;

    if (levelsGained > 0) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.levelUpBg,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌟', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text('LEVEL UP! Lv.${levelBefore + levelsGained}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.levelUpBg),
                child: const Text('계속하기'),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ "${quest.title}" 완료! EXP +${quest.rewardExp}')),
      );
    }
  }
}
