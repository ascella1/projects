import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/quest.dart';
import '../../core/config/supabase_config.dart';
import '../../state/app_state.dart';
import '../quest/quest_complete_screen.dart';
import '../quest/level_up_screen.dart';
import '../quest/special_complete_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _Header(state: state),
              ),
            ),

            // ── 일반 퀘스트 ───────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: _SectionTitle(),
              ),
            ),
            state.todayQuests.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _QuestCard(quest: state.todayQuests[i]),
                        childCount: state.todayQuests.length,
                      ),
                    ),
                  ),

            // ── 스페셜 미션 ───────────────────────────────────────────────────
            if (state.todaySpecialMission != null) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: _SpecialSectionTitle(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _SpecialMissionCard(),
                ),
              ),
            ],

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: _BottomInfo(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    final profile = state.userProfile;
    final progress = profile?.levelProgress ?? 0.0;
    final xpCurrent = profile?.xpInCurrentLevel ?? 0;
    final xpNext = profile?.xpForNextLevel ?? 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUEST DAY',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hello, ${state.userProfile?.nickname ?? ''}',
                  style: TextStyle(
                    color: qc.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _StreakBadge(streak: state.streak),
                const SizedBox(width: 8),
                _LevelBadge(level: state.level),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: qc.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$xpCurrent XP',
              style: TextStyle(color: qc.textMuted, fontSize: 10),
            ),
            Text(
              'NEXT LV: $xpNext XP',
              style: const TextStyle(
                  color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Section Titles ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "TODAY'S QUESTS",
          style: TextStyle(
            color: context.qc.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '2',
            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SpecialSectionTitle extends StatelessWidget {
  const _SpecialSectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('⚡', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          'SPECIAL MISSION',
          style: TextStyle(
            color: context.qc.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '선착순 1명',
            style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

// ─── 일반 퀘스트 카드 ─────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  final Quest quest;
  const _QuestCard({required this.quest});

  Color get _catColor {
    switch (quest.category) {
      case QuestCategory.exploration: return AppColors.exploration;
      case QuestCategory.social: return AppColors.social;
      case QuestCategory.creative: return AppColors.creative;
      case QuestCategory.thinking: return AppColors.thinking;
      case QuestCategory.action: return AppColors.action;
      case QuestCategory.relationship: return AppColors.relationship;
      case QuestCategory.random: return AppColors.random;
    }
  }

  Color get _comfortColor {
    switch (quest.comfortLevel) {
      case ComfortLevel.safe: return AppColors.safe;
      case ComfortLevel.normal: return AppColors.normal;
      case ComfortLevel.challenge: return AppColors.challenge;
      case ComfortLevel.crazy: return AppColors.crazy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final qc = context.qc;
    final isCompleted = state.isQuestCompleted(quest.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: qc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.safe.withValues(alpha: 0.5)
              : _catColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: qc.isDark
            ? null
            : [BoxShadow(color: _catColor.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: BoxDecoration(
              color: _catColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _Badge(label: quest.categoryName, color: _catColor),
                const SizedBox(width: 6),
                _Badge(label: quest.comfortLevelName, color: _comfortColor),
                const Spacer(),
                Text(quest.difficultyStars,
                    style: const TextStyle(color: AppColors.accent, fontSize: 12, letterSpacing: 1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest.title,
                            style: TextStyle(
                              color: qc.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            quest.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: qc.textSecondary, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '+${quest.baseXP} XP',
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    if (isCompleted) _DoneChip() else _CompleteButton(questId: quest.id),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 스페셜 미션 카드 ─────────────────────────────────────────────────────────

class _SpecialMissionCard extends StatefulWidget {
  const _SpecialMissionCard();

  @override
  State<_SpecialMissionCard> createState() => _SpecialMissionCardState();
}

class _SpecialMissionCardState extends State<_SpecialMissionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _updateRemaining());
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _remaining = midnight.difference(now);
  }

  String get _countdownText {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final mission = state.todaySpecialMission!;
    final qc = context.qc;

    final isLoading = state.specialLoading;
    final claim = state.specialClaim;
    final claimedByMe = state.specialClaimedByMe;
    final error = state.specialError;
    final notConfigured = !SupabaseConfig.isConfigured;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (ctx, child) {
        final glowOpacity = claim == null && !claimedByMe
            ? 0.15 + _pulseAnim.value * 0.20
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: qc.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: claimedByMe
                  ? AppColors.accent.withValues(alpha: 0.8)
                  : AppColors.accent.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: glowOpacity),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더 바
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.18),
                      AppColors.primary.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⚡ SPECIAL',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1),
                      ),
                    ),
                    const Spacer(),
                    if (claim == null && !claimedByMe)
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 12, color: qc.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            _countdownText,
                            style: TextStyle(
                                color: qc.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // 미션 내용
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mission.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mission.title,
                                style: TextStyle(
                                  color: qc.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mission.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: qc.textSecondary, fontSize: 13, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // XP + 상태/버튼
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${mission.bonusXp} XP',
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Spacer(),
                        _buildActionWidget(
                          context: context,
                          state: state,
                          mission: mission,
                          isLoading: isLoading,
                          claim: claim,
                          claimedByMe: claimedByMe,
                          error: error,
                          notConfigured: notConfigured,
                        ),
                      ],
                    ),

                    // 클레임된 경우 위너 표시
                    if (claim != null && !claimedByMe) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: qc.divider.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${claim.claimerNickname}님이 오늘 먼저 완료했어요',
                                style: TextStyle(color: qc.textMuted, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 에러
                    if (error != null && claim == null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 13, color: qc.textMuted),
                          const SizedBox(width: 6),
                          Text(error, style: TextStyle(color: qc.textMuted, fontSize: 11)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.read<AppState>().refreshSpecialMission(),
                            child: const Text('재시도',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionWidget({
    required BuildContext context,
    required AppState state,
    required mission,
    required bool isLoading,
    required claim,
    required bool claimedByMe,
    required String? error,
    required bool notConfigured,
  }) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
      );
    }

    if (claimedByMe) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆', style: TextStyle(fontSize: 13)),
            SizedBox(width: 4),
            Text('내가 완료!',
                style: TextStyle(
                    color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    if (claim != null) {
      // 다른 사람이 이미 완료
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.qc.divider,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '마감됨',
          style: TextStyle(
              color: context.qc.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (notConfigured) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.qc.divider,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '설정 필요',
          style: TextStyle(color: context.qc.textMuted, fontSize: 12),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _onClaimTap(context, state, mission),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('도전하기'),
    );
  }

  Future<void> _onClaimTap(BuildContext context, AppState state, mission) async {
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final result = await state.claimSpecialMission();
      await navigator.push(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, _) =>
              SpecialCompleteScreen(result: result, mission: mission),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }
}

// ─── 공통 위젯 ────────────────────────────────────────────────────────────────

class _CompleteButton extends StatelessWidget {
  final String questId;
  const _CompleteButton({required this.questId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _onTap(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('완료하기'),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    // Capture before any await — _CompleteButton unmounts when quest completes
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final result = await context.read<AppState>().completeQuest(questId);

      await navigator.push(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, _) => QuestCompleteScreen(entry: result.entry),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );

      if (result.didLevelUp) {
        await navigator.push(
          PageRouteBuilder(
            pageBuilder: (ctx, anim, _) =>
                LevelUpScreen(newLevel: result.newLevel, newTitle: result.newTitle),
            transitionsBuilder: (ctx, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }
}

class _DoneChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.safe.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.safe.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: AppColors.safe, size: 14),
          SizedBox(width: 4),
          Text('완료',
              style: TextStyle(
                  color: AppColors.safe, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            'LV.$level',
            style: const TextStyle(
                color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _BottomInfo extends StatelessWidget {
  final AppState state;
  const _BottomInfo({required this.state});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    final completed = state.todayCompletedIds.length;
    final total = state.todayQuests.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: qc.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 진행도',
                style: TextStyle(
                    color: qc.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                '$completed / $total',
                style: const TextStyle(
                    color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: qc.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$streak일',
            style: const TextStyle(
              color: Color(0xFFE65100),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
