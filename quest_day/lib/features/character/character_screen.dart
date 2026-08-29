import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/level_titles.dart';
import '../../core/services/stat_config.dart';
import '../../state/app_state.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.userProfile;
    final stats = state.stats;
    final qc = context.qc;

    final currentTitle = LevelTitles.titleForLevel(state.level);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHARACTER',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile?.nickname ?? '',
                style: TextStyle(
                  color: qc.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (currentTitle != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '🏷️ $currentTitle',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _LevelCard(state: state),
              const SizedBox(height: 24),
              Text(
                'STATS',
                style: TextStyle(
                  color: qc.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              ...StatConfig.all.map((def) => _StatBar(
                    label: def.label,
                    icon: def.icon,
                    color: def.color,
                    value: stats[def.key] ?? 0,
                    maxValue: 200,
                  )),
              const SizedBox(height: 24),
              _StreakCard(streak: state.streak),
            ],
          ),
        ),
      ),
    );
  }
}


class _LevelCard extends StatelessWidget {
  final AppState state;
  const _LevelCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final profile = state.userProfile;
    final progress = profile?.levelProgress ?? 0.0;
    final xpCurrent = profile?.xpInCurrentLevel ?? 0;
    final xpNext = profile?.xpForNextLevel ?? 80;
    final qc = context.qc;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: qc.isDark ? 0.3 : 0.15),
            AppColors.primaryDark.withValues(alpha: qc.isDark ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LEVEL ${state.level}',
                    style: TextStyle(
                      color: qc.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '총 ${state.totalXP} XP',
                    style: TextStyle(color: qc.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: qc.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$xpCurrent / $xpNext XP',
                style: TextStyle(color: qc.textSecondary, fontSize: 12),
              ),
              Text(
                'LEVEL ${state.level + 1}까지',
                style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatefulWidget {
  final String label;
  final String icon;
  final Color color;
  final int value;
  final int maxValue;
  const _StatBar({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.maxValue,
  });

  @override
  State<_StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<_StatBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    final progress = (widget.value / widget.maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: qc.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.value}',
                style: TextStyle(
                  color: widget.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _anim,
            builder: (ctx, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress * _anim.value,
                backgroundColor: qc.divider,
                valueColor: AlwaysStoppedAnimation(widget.color),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  String get _message {
    if (streak >= 100) return '전설적인 탐험가 🏆';
    if (streak >= 30) return '베테랑 모험가 🎖️';
    if (streak >= 7) return '꾸준한 퀘스터 🌟';
    if (streak >= 3) return '새로운 습관 만드는 중 🌱';
    if (streak >= 1) return '첫 발걸음을 뗐어요 👣';
    return '오늘 첫 퀘스트를 시작해보세요!';
  }

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: qc.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak일 연속',
                style: TextStyle(
                  color: qc.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _message,
                style: TextStyle(color: qc.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
