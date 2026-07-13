import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/level_config_service.dart';
import '../../../onboarding/presentation/views/goal_wizard_screen.dart';
import '../../../quest/presentation/providers/user_provider.dart';
import 'journey_map_screen.dart';
import 'tabs/achievements_tab.dart';
import 'tabs/garden_tab.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/loot_box_tab.dart';

// 앱의 메인 셸(shell). 하단 탭 전환과, 어느 탭에 있든 떠야 하는 전역
// 다이얼로그(스트릭 보상/등급 해금)만 담당한다. 각 탭의 실제 기능은
// tabs/ 폴더의 개별 파일에 있다.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final cfg = LevelConfigService.current;

    // 7일 연속 접속 보상 & 등급 해금은 탭과 무관하게 항상 감지해야 하므로
    // 셸(shell)에서 직접 처리한다.
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
              ? _buildMainApp()
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
                    icon: Icon(Icons.map), label: '여정 지도'),
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

  Widget _buildMainApp() {
    switch (_currentTab) {
      case 0:
        return const GardenTab();
      case 1:
        return const JourneyMapScreen();
      case 2:
        return LootBoxTab(onGoToInventory: () => setState(() => _currentTab = 3));
      case 3:
        return const InventoryTab();
      case 4:
        return AchievementsTab(onReset: () => setState(() => _currentTab = 0));
      default:
        return const SizedBox();
    }
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
}
