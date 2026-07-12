import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/item_service.dart';
import '../../../../core/services/level_config_service.dart';
import '../../../../core/utils/character_util.dart';
import '../../../../core/utils/stat_util.dart';
import '../../../onboarding/presentation/views/goal_wizard_screen.dart';
import '../../../quest/domain/entities/quest_entity.dart';
import '../../../quest/presentation/providers/quest_provider.dart';
import '../../../quest/presentation/providers/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;

  // 상자 오픈 애니메이션
  bool _isOpeningBox = false;
  late AnimationController _boxAnimController;

  // 전체 악세사리 목록. assets/data/mokpyo_item.json 에서 로드된다.
  List<Map<String, String>> _accessories = [];

  @override
  void initState() {
    super.initState();
    _boxAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadAccessories();
  }

  Future<void> _loadAccessories() async {
    final items = await ItemService.loadItems();
    if (!mounted) return;
    setState(() => _accessories = items);
  }

  @override
  void dispose() {
    _boxAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final cfg = LevelConfigService.current;

    // 7일 연속 접속 보상 & 레벨업은 각 이벤트에서 직접 처리
    ref.listen<UserState>(userProvider, (prev, next) {
      if (next.pendingStreakReward &&
          !(prev?.pendingStreakReward ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showStreakRewardDialog();
          ref.read(userProvider.notifier).clearPendingStreakReward();
        });
      }

      // 소목표/중목표/대목표 해금 레벨 도달 시 알림 (JSON 설정 기반)
      final prevLevel = prev?.level ?? 1;
      final unlocked = <String>[];
      final lv3 = cfg.tierUnlockLevelByDepth[3]!;
      final lv2 = cfg.tierUnlockLevelByDepth[2]!;
      final lv1 = cfg.tierUnlockLevelByDepth[1]!;
      if (prevLevel < lv3 && next.level >= lv3) unlocked.add('🥉 소목표');
      if (prevLevel < lv2 && next.level >= lv2) unlocked.add('🥈 중목표');
      if (prevLevel < lv1 && next.level >= lv1) unlocked.add('🏆 대목표');
      if (unlocked.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showTierUnlockDialog(unlocked);
        });
      }
    });

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
          child: userState.hasCompletedOnboarding
              ? _buildMainApp(userState)
              : const GoalWizardScreen(),
        ),
      ),
      bottomNavigationBar: userState.hasCompletedOnboarding
          ? BottomNavigationBar(
              currentIndex: _currentTab,
              onTap: (i) => setState(() => _currentTab = i),
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.yard), label: '나의 정원'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.card_giftcard), label: '상자 오픈'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.backpack), label: '인벤토리'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events), label: '업적 & 스탯'),
              ],
            )
          : null,
    );
  }

  // ===================== 메인 앱 =====================

  Widget _buildMainApp(UserState userState) {
    switch (_currentTab) {
      case 0:
        return _buildTabGarden(userState);
      case 1:
        return _buildTabLootBox(userState);
      case 2:
        return _buildTabInventory(userState);
      case 3:
        return _buildTabAchievements(userState);
      default:
        return const SizedBox();
    }
  }

  // -------------------- 탭 0: 나의 정원 --------------------

  Widget _buildTabGarden(UserState userState) {
    final questsAsync = ref.watch(questListProvider('g_active'));
    final cfg = LevelConfigService.current;

    final charEmoji = characterEmoji(userState.characterType);
    final speechBubble = characterSpeech(userState.characterType);

    String? accessoryEmoji;
    if (userState.equippedAccessory != null) {
      final acc = _accessories.firstWhere(
          (e) => e['id'] == userState.equippedAccessory,
          orElse: () => {});
      if (acc.isNotEmpty) accessoryEmoji = acc['name']!.split(' ')[0];
    }

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
                              child: Text(charEmoji,
                                  style: const TextStyle(fontSize: 22)),
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Text(charEmoji, style: const TextStyle(fontSize: 96)),
                      if (accessoryEmoji != null)
                        Positioned(
                          top: -34,
                          child: Text(accessoryEmoji,
                              style: const TextStyle(fontSize: 50)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                ],
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
                      final tiers = [
                        (
                          depth: 4,
                          title: '🌱 오늘의 실천 목표',
                          unlocked: true,
                        ),
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

                      final sections = <Widget>[];
                      for (final tier in tiers) {
                        if (!tier.unlocked) continue;
                        final items = quests
                            .where((q) => q.depth == tier.depth)
                            .toList();
                        if (items.isEmpty) continue;
                        sections.add(_questSectionHeader(tier.title));
                        sections.addAll(items.map(_questTile));
                      }

                      if (sections.isEmpty) {
                        return const Center(
                          child: Text(
                            '🎉 오늘의 퀘스트를 전부 달성했습니다!\n내일 새로운 목표가 찾아옵니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey, height: 1.5),
                          ),
                        );
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

  // -------------------- 탭 1: 상자 오픈 --------------------

  Widget _buildTabLootBox(UserState userState) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('보물 보관소',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            '퀘스트를 완료하고\n획득한 상자를 열어보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _boxAnimController,
            builder: (context, child) {
              final shake = sin(_boxAnimController.value * 2 * pi * 5) *
                  12 *
                  (1.0 - _boxAnimController.value);
              final scale = 1.0 +
                  sin(_boxAnimController.value * pi) *
                      0.15 *
                      (1.0 - _boxAnimController.value);
              return Transform.translate(
                offset: Offset(shake, 0),
                child: Transform.scale(
                  scale: scale,
                  child: const Text('📦', style: TextStyle(fontSize: 120)),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            '보유 상자: ${userState.boxesCount}개',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '인벤토리: ${userState.inventory.length}/${_accessories.length} 수집',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (userState.boxesCount <= 0 ||
                      _isOpeningBox ||
                      _accessories.isEmpty)
                  ? null
                  : () async {
                      setState(() => _isOpeningBox = true);
                      await _boxAnimController.forward(from: 0.0);

                      final random = Random();
                      final item =
                          _accessories[random.nextInt(_accessories.length)];
                      final success = await ref
                          .read(userProvider.notifier)
                          .openBox(item['id']!);

                      setState(() => _isOpeningBox = false);
                      if (success && mounted) {
                        _showItemAcquiredDialog(item);
                      }
                    },
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                elevation: 4,
              ),
              child: _isOpeningBox
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('✨ 상자 열기',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),
          if (userState.boxesCount <= 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '🌱 일일 퀘스트를 완료하면 상자를 얻을 수 있어요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------- 탭 2: 인벤토리 --------------------

  Widget _buildTabInventory(UserState userState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎒 가방 (인벤토리)',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              SizedBox(height: 4),
              Text('악세사리를 탭해서 캐릭터에게 장착시켜 주세요.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: userState.inventory.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎒', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          '아직 획득한 아이템이 없어요.\n상자를 열어 악세사리를 모아보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.withValues(alpha: 0.9),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: userState.inventory.length,
                  itemBuilder: (context, index) {
                    final id = userState.inventory[index];
                    final item = _accessories.firstWhere(
                        (e) => e['id'] == id,
                        orElse: () => {});
                    if (item.isEmpty) return const SizedBox();
                    final name = item['name']!;
                    final isEquipped = userState.equippedAccessory == id;

                    return GestureDetector(
                      onTap: () {
                        if (isEquipped) {
                          ref.read(userProvider.notifier).equipAccessory(null);
                        } else {
                          ref.read(userProvider.notifier).equipAccessory(id);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isEquipped
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6)
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name.split(' ')[0],
                                    style: const TextStyle(fontSize: 36),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name.substring(name.indexOf(' ') + 1),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isEquipped)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('장착',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -------------------- 탭 3: 업적 & 스탯 --------------------

  Widget _buildTabAchievements(UserState userState) {
    final questsAsync = ref.watch(questListProvider('g_active'));

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
                onPressed: _showResetConfirmDialog,
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
                    '${userState.inventory.length}/${_accessories.length}',
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
                      width: 1, height: 36, color: Colors.grey.withValues(alpha: 0.3)),
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

  void _showStreakRewardDialog() {
    final cfg = LevelConfigService.current;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🔥 ${cfg.streakDaysRequired}일 연속 접속!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.streakBadgeFg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎊', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(
              '${cfg.streakDaysRequired}일 동안 꾸준히 목표를 실천했군요!\n특별 상자 ${cfg.streakBonusBoxes}개를 드립니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  cfg.streakBonusBoxes,
                  (_) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('📦', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.streakBadgeFg),
              child: const Text('감사합니다!'),
            ),
          ),
        ],
      ),
    );
  }

  void _showTierUnlockDialog(List<String> unlockedTiers) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔓 새로운 목표 해금!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(
              '${unlockedTiers.join(', ')}가(이) 나타났어요!\n오늘의 실천 목표 아래에서 확인해보세요.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인했어요!'),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemAcquiredDialog(Map<String, String> item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✨ 아이템 획득! ✨',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.streakBadgeFg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item['name']!.split(' ')[0],
                style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 10),
            Text(
              item['name']!.substring(item['name']!.indexOf(' ') + 1),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              item['desc']!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _currentTab = 2);
              },
              child: const Text('인벤토리에서 장착하기'),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog() {
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
              setState(() => _currentTab = 0);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  // ===================== 헬퍼 위젯 =====================

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

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
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
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _rewardItem(String emoji, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label,
            style:
                TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
      ],
    );
  }
}
