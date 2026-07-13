import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/item_service.dart';
import '../../../../../core/utils/stat_util.dart';
import '../../../../quest/domain/entities/quest_entity.dart';
import '../../../../quest/presentation/providers/quest_provider.dart';
import '../../../../quest/presentation/providers/user_provider.dart';

// 탭 3: 업적 & 스탯 — 전체 레벨/능력치/달성 기록과 데이터 초기화.
class AchievementsTab extends ConsumerWidget {
  const AchievementsTab({super.key, required this.onReset});

  // 데이터 초기화 후 "나의 정원" 탭으로 돌아가기 위한 콜백.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final questsAsync = ref.watch(questListProvider('g_active'));
    final accessories = ref.watch(itemListProvider).value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🏆 성장 현황',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              IconButton(
                onPressed: () => _showResetConfirmDialog(context, ref),
                tooltip: '데이터 초기화',
                icon: const Icon(Icons.refresh,
                    size: 20, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                    '⭐ 전체 레벨', 'Lv.${userState.level}', AppColors.primarySoft),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard('🔥 연속 접속', '${userState.currentStreak}일',
                    AppColors.streakBadgeBg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                    '🎒 수집 아이템',
                    '${userState.inventory.length}/${accessories.length}',
                    const Color(0xFFE8EAF6)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('능력치 레벨',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 14),
                  ...() {
                    final statsToShow = userState.recommendedStats.isNotEmpty
                        ? userState.recommendedStats
                        : userState.statLevels.keys.toList();
                    final rows = <Widget>[];
                    for (var i = 0; i < statsToShow.length; i++) {
                      final stat = statsToShow[i];
                      final info = statInfo(stat);
                      if (i > 0) rows.add(const SizedBox(height: 10));
                      rows.add(_statRow(
                        '${info.emoji} ${info.label}',
                        userState.statLevels[stat] ?? 0,
                        info.color,
                      ));
                    }
                    return rows;
                  }(),
                  const SizedBox(height: 8),
                  const Text(
                    '퀘스트 완료 시 해당 능력치 레벨이 1씩 오릅니다.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('달성 기록',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          questsAsync.when(
            data: (quests) {
              final completed = quests
                  .where((q) => q.status == QuestStatus.completed)
                  .toList();
              if (completed.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '아직 완료한 퀘스트가 없습니다.\n정원에서 일일 퀘스트를 체크해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                );
              }
              return Column(
                children: completed.map((quest) {
                  final depthLabel =
                      ['', '대목표', '중목표', '소목표', '일일 퀘스트'][quest.depth];
                  final depthColor = AppColors.depthColors[quest.depth];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: depthColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(depthLabel,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: depthColor)),
                      ),
                      title: Text(quest.title,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      trailing: const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('달성 내역 오류: $err')),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 데이터 초기화'),
        content: const Text(
            '캐릭터, 목표, 퀘스트, 획득 아이템이 모두 삭제됩니다.\n정말 초기화하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(userProvider.notifier).resetAll();
              onReset();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _statRow(String name, int level, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: min(level / 20.0, 1.0),
              backgroundColor: Colors.grey.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text('Lv.$level',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}
