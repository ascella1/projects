import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/item_service.dart';
import '../../../../../core/services/level_config_service.dart';
import '../../../../../core/utils/character_util.dart';
import '../../../../../core/utils/item_util.dart';
import '../../../../quest/domain/entities/quest_entity.dart';
import '../../../../quest/presentation/providers/quest_provider.dart';
import '../../../../quest/presentation/providers/user_provider.dart';

// 탭 0: 나의 정원 — 캐릭터(먹이주기/놀아주기/체크인 인사)와 오늘의 실천 목표를
// 포함한 퀘스트 트리를 보여준다.
class GardenTab extends ConsumerStatefulWidget {
  const GardenTab({super.key});

  @override
  ConsumerState<GardenTab> createState() => _GardenTabState();
}

class _GardenTabState extends ConsumerState<GardenTab>
    with TickerProviderStateMixin {
  // 캐릭터 탭 반응 애니메이션(바운스+뒤뚱거림)
  late AnimationController _characterAnimController;
  // 탭할 때마다 새로 뽑는 대사. null이면 기분에 맞는 기본 대사를 보여준다.
  String? _currentSpeech;

  // 먹이주기/놀아주기 시 캐릭터 위로 떠오르는 이모지 파티클 애니메이션
  late AnimationController _particleAnimController;
  String? _particleEmoji;

  @override
  void initState() {
    super.initState();
    _characterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _particleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _particleEmoji = null);
        }
      });
  }

  @override
  void dispose() {
    _characterAnimController.dispose();
    _particleAnimController.dispose();
    super.dispose();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _onCharacterTap(
    UserState userState,
    CharacterMood mood,
    ({int total, int completedToday, int remaining}) summary,
  ) {
    setState(() {
      _currentSpeech = randomSpeech(userState.characterType, mood);
    });
    _characterAnimController.forward(from: 0);

    if (userState.lastGreetedDate != _todayStr()) {
      ref.read(userProvider.notifier).markGreetedToday();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCheckInDialog(userState, mood, summary);
      });
    }
  }

  // 먹이주기/놀아주기: 루틴 완료 여부와 무관한 순수 애정 표현 상호작용.
  // 캐릭터가 반응(대사+바운스)하고 이모지 파티클이 떠오른다.
  void _onFeedOrPlay(String characterType, String emoji, String speech) {
    setState(() {
      _particleEmoji = emoji;
      _currentSpeech = speech;
    });
    _particleAnimController.forward(from: 0);
    _characterAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final questsAsync = ref.watch(questListProvider('g_active'));
    final accessories = ref.watch(itemListProvider).value ?? [];
    final cfg = LevelConfigService.current;

    final mood = moodFor(
      userState.lastRoutineDate,
      neutralAfterDays: cfg.moodNeutralAfterDays,
      hungryAfterDays: cfg.moodHungryAfterDays,
    );
    final speechBubble =
        _currentSpeech ?? randomSpeech(userState.characterType, mood);

    Map<String, String>? equippedItem;
    if (userState.equippedAccessory != null) {
      final acc = accessories.firstWhere(
          (e) => e['id'] == userState.equippedAccessory,
          orElse: () => {});
      if (acc.isNotEmpty) equippedItem = acc;
    }

    final dailyQuests = questsAsync.value?.where((q) => q.depth == 4) ?? [];
    final today = DateTime.now();
    final dailySummary = (
      total: dailyQuests.length,
      completedToday: dailyQuests
          .where((q) =>
              q.status == QuestStatus.completed &&
              q.completedAt != null &&
              q.completedAt!.year == today.year &&
              q.completedAt!.month == today.month &&
              q.completedAt!.day == today.day)
          .length,
      remaining:
          dailyQuests.where((q) => q.status != QuestStatus.completed).length,
    );

    return Column(
      children: [
        // 상단 유저 정보 카드
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.avatarBg,
                              child: characterVisual(
                                  userState.characterType, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lv.${userState.level} 정원사',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    userState.goal,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _badge('🎁 상자 ${userState.boxesCount}개',
                              AppColors.boxBadgeBg, AppColors.boxBadgeFg),
                          const SizedBox(height: 4),
                          _badge(
                              '🔥 ${userState.currentStreak}일 연속',
                              AppColors.streakBadgeBg,
                              AppColors.streakBadgeFg),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('EXP',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: userState.exp / cfg.expPerLevel,
                            backgroundColor:
                                Colors.grey.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primaryLight),
                            minHeight: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${userState.exp}/${cfg.expPerLevel}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(cfg.streakDaysRequired, (i) {
                      final filled = i < userState.currentStreak;
                      return Expanded(
                        child: Container(
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: filled
                                ? AppColors.streakBadgeFg
                                : Colors.grey.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cfg.streakDaysRequired}일 연속 접속 달성 시 상자 ${cfg.streakBonusBoxes}개 보상!',
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 캐릭터 뷰
        Expanded(
          flex: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withValues(alpha: 0.55),
                        blurRadius: 45,
                        spreadRadius: 12)
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _onCharacterTap(userState, mood, dailySummary),
                          child: AnimatedBuilder(
                            animation: _characterAnimController,
                            builder: (context, child) {
                              final t = _characterAnimController.value;
                              final bounce = sin(t * pi) * 0.18;
                              final wiggle = sin(t * pi * 4) * 0.06 * (1 - t);
                              final baseTilt =
                                  mood == CharacterMood.hungry ? -0.05 : 0.0;
                              return Transform.rotate(
                                angle: baseTilt + wiggle,
                                child: Transform.scale(
                                  scale: 1 + bounce,
                                  child: child,
                                ),
                              );
                            },
                            child: Opacity(
                              opacity: mood == CharacterMood.hungry ? 0.7 : 1.0,
                              child: characterVisual(userState.characterType,
                                  size: 96),
                            ),
                          ),
                        ),
                        if (equippedItem != null)
                          Positioned(
                            top: -34,
                            child: itemVisual(equippedItem, size: 50),
                          ),
                        Positioned(
                          right: -6,
                          top: 6,
                          child: Text(moodIndicatorEmoji(mood),
                              style: const TextStyle(fontSize: 22)),
                        ),
                        if (_particleEmoji != null)
                          AnimatedBuilder(
                            animation: _particleAnimController,
                            builder: (context, child) {
                              final t = _particleAnimController.value;
                              return Positioned(
                                top: 10 - (60 * t),
                                child: Opacity(
                                  opacity: (1 - t).clamp(0.0, 1.0),
                                  child: Text(_particleEmoji!,
                                      style: const TextStyle(fontSize: 28)),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () =>
                          _onCharacterTap(userState, mood, dailySummary),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6)
                          ],
                        ),
                        child: Text(
                          speechBubble,
                          style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF5D4037)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _interactionButton(
                          emoji: '🍖',
                          label: '먹이주기',
                          onTap: () => _onFeedOrPlay(
                            userState.characterType,
                            '🍖',
                            randomFeedSpeech(userState.characterType),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _interactionButton(
                          emoji: '🎾',
                          label: '놀아주기',
                          onTap: () => _onFeedOrPlay(
                            userState.characterType,
                            '🎾',
                            randomPlaySpeech(userState.characterType),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 퀘스트 패널
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: questsAsync.when(
                    data: (quests) {
                      final higherTiers = [
                        (
                          depth: 3,
                          title:
                              '🥉 소목표 (Lv.${cfg.tierUnlockLevelByDepth[3]} 해금)',
                          unlocked:
                              userState.level >= cfg.tierUnlockLevelByDepth[3]!,
                        ),
                        (
                          depth: 2,
                          title:
                              '🥈 중목표 (Lv.${cfg.tierUnlockLevelByDepth[2]} 해금)',
                          unlocked:
                              userState.level >= cfg.tierUnlockLevelByDepth[2]!,
                        ),
                        (
                          depth: 1,
                          title:
                              '🏆 대목표 (Lv.${cfg.tierUnlockLevelByDepth[1]} 해금)',
                          unlocked:
                              userState.level >= cfg.tierUnlockLevelByDepth[1]!,
                        ),
                      ];

                      // 일일 퀘스트는 언제나 표시하고, 직접 추가할 수 있는
                      // "+" 버튼을 헤더에 함께 둔다. 완료하지 않은 항목이
                      // 위로, 완료한 항목은 취소선과 함께 아래로 내려간다.
                      final dailyQuests = _sortedByStatus(
                          quests.where((q) => q.depth == 4).toList());
                      final allDailyDone = dailyQuests.isNotEmpty &&
                          dailyQuests
                              .every((q) => q.status == QuestStatus.completed);
                      final sections = <Widget>[
                        _questSectionHeaderWithAdd(
                            '🌱 오늘의 실천 목표', userState),
                        if (dailyQuests.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '아직 오늘의 실천 목표가 없어요. + 버튼으로 추가해보세요!',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          )
                        else ...[
                          if (allDailyDone)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '🎉 오늘의 실천 목표를 전부 달성했습니다! + 버튼으로 더 추가할 수 있어요.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ...dailyQuests.map(_questTile),
                        ],
                      ];

                      for (final tier in higherTiers) {
                        if (!tier.unlocked) continue;
                        final items = _sortedByStatus(quests
                            .where((q) => q.depth == tier.depth)
                            .toList());
                        if (items.isEmpty) continue;
                        sections.add(_questSectionHeader(tier.title));
                        sections.addAll(items.map(_questTile));
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                        children: sections,
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (err, _) =>
                        Center(child: Text('오류: $err')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===================== 다이얼로그 =====================

  void _showSuccessRewardDialog(
    Quest quest, {
    required int levelBefore,
    required int levelsGained,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 퀘스트 달성!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '"오늘 하루도 멋지게 목표를 향해 나아갔군요!"',
              style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _rewardItem('⭐', 'EXP +${quest.rewardExp}', AppColors.primary),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.withValues(alpha: 0.3)),
                  _rewardItem('📦', '랜덤 상자 1개', AppColors.streakBadgeFg),
                ],
              ),
            ),
            if (levelsGained > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.streakBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌟', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'LEVEL UP! Lv.${levelBefore + levelsGained}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.streakBadgeFg,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (levelsGained > 0 && mounted) {
                  _showLevelUpDialog(levelBefore + levelsGained, levelsGained);
                }
              },
              child: const Text('수락하기'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelUpDialog(int newLevel, int levelsGained) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.levelUpBg,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text(
              'LEVEL UP!',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Lv.$newLevel 달성!',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '"한 걸음씩 나아가는 당신,\n이미 충분히 멋집니다."',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.levelUpBg,
              ),
              child: const Text('계속하기'),
            ),
          ],
        ),
      ),
    );
  }

  // 하루 중 캐릭터를 처음 탭했을 때 뜨는 "체크인" 다이얼로그.
  // 오늘의 일일 퀘스트 진행 상황을 캐릭터에게 보고하는 느낌을 주기 위함.
  void _showCheckInDialog(
    UserState userState,
    CharacterMood mood,
    ({int total, int completedToday, int remaining}) summary,
  ) {
    final days = daysSince(userState.lastRoutineDate);
    String neglectLine = '';
    if (mood == CharacterMood.hungry && days > 0) {
      neglectLine = '\n마지막으로 함께한 지 $days일이 지났어요.';
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            '${moodIndicatorEmoji(mood)} ${characterLabel(userState.characterType)}의 인사',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            characterVisual(userState.characterType, size: 64),
            const SizedBox(height: 12),
            Text(
              randomSpeech(userState.characterType, mood) + neglectLine,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                summary.total == 0
                    ? '오늘의 일일 퀘스트가 아직 없어요.'
                    : '오늘 일일 퀘스트 ${summary.completedToday}/${summary.total} 완료\n남은 퀘스트 ${summary.remaining}개',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('알겠어요!'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAdHocQuestDialog(UserState userState) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✏️ 오늘의 목표 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '예: 갑자기 영단어 10개 외우기',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              Navigator.of(ctx).pop();
              final stats = userState.recommendedStats.isNotEmpty
                  ? userState.recommendedStats
                  : ['career'];
              await ref
                  .read(questListProvider('g_active').notifier)
                  .addAdHocQuest(
                    goalId: 'g_active',
                    title: title,
                    rewardStats: stats,
                  );
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  // ===================== 헬퍼 위젯 =====================

  // 완료하지 않은 퀘스트가 위로, 완료한 퀘스트는 아래로 내려가도록 정렬한다.
  // (같은 상태 안에서는 원래 순서를 유지하는 안정 정렬)
  List<Quest> _sortedByStatus(List<Quest> quests) {
    final indexed = quests.asMap().entries.toList();
    indexed.sort((a, b) {
      final aDone = a.value.status == QuestStatus.completed;
      final bDone = b.value.status == QuestStatus.completed;
      if (aDone == bDone) return a.key.compareTo(b.key);
      return aDone ? 1 : -1;
    });
    return indexed.map((e) => e.value).toList();
  }

  Widget _questSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
      ),
    );
  }

  Widget _questSectionHeaderWithAdd(String title, UserState userState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          IconButton(
            onPressed: () => _showAddAdHocQuestDialog(userState),
            icon: const Icon(Icons.add_circle,
                color: AppColors.primary, size: 22),
            tooltip: '오늘의 목표 직접 추가하기',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _questTile(Quest quest) {
    final isDone = quest.status == QuestStatus.completed;
    return Card(
      color: isDone ? AppColors.surfaceDone : AppColors.surfaceMuted,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Checkbox(
          value: isDone,
          onChanged: isDone
              ? null
              : (val) async {
                  if (val != true || !mounted) return;
                  final levelBefore = ref.read(userProvider).level;
                  final levelsGained = await ref
                      .read(questListProvider('g_active').notifier)
                      .completeQuest(quest.id);
                  if (!mounted) return;
                  _showSuccessRewardDialog(
                    quest,
                    levelBefore: levelBefore,
                    levelsGained: levelsGained,
                  );
                },
        ),
        title: Text(
          quest.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            _expChip('EXP +${quest.rewardExp}'),
            const SizedBox(width: 8),
            const Text('🎁 상자 1개',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _interactionButton({
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(text,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _expChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _rewardItem(String emoji, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 12)),
      ],
    );
  }
}
