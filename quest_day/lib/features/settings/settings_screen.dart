import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/quest.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.userProfile;
    final qc = context.qc;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SETTINGS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '설정',
                style: TextStyle(
                  color: qc.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 32),

              // Appearance (theme toggle)
              _SectionLabel(label: 'APPEARANCE'),
              const SizedBox(height: 12),
              _ThemeToggleTile(currentMode: state.themeMode),

              const SizedBox(height: 32),

              // Comfort Zone
              _SectionLabel(label: 'COMFORT ZONE'),
              const SizedBox(height: 12),
              ..._comfortOptions.map((opt) => _ComfortOption(
                    label: opt.label,
                    description: opt.description,
                    color: opt.color,
                    selected: profile?.comfortZone == opt.zone,
                    onTap: () => context.read<AppState>().updateComfortZone(opt.zone),
                  )),

              const SizedBox(height: 32),
              _SectionLabel(label: 'QUEST'),
              const SizedBox(height: 12),
              const _PremiumLockedTile(
                icon: '🔄',
                label: '오늘 퀘스트 새로고침',
                subtitle: '퀘스트가 마음에 안 들면 교체할 수 있어요',
              ),

              const SizedBox(height: 32),
              _SectionLabel(label: 'ACCOUNT'),
              const SizedBox(height: 12),
              _SettingTile(
                icon: '🗑️',
                label: '데이터 초기화',
                subtitle: '모든 진행 상황이 삭제됩니다',
                isDestructive: true,
                onTap: () => _showResetDialog(context),
              ),

              const SizedBox(height: 32),
              _SectionLabel(label: 'APP'),
              const SizedBox(height: 12),
              _InfoTile(label: '버전', value: '1.0.0'),
              const SizedBox(height: 8),
              _InfoTile(label: '빌드', value: 'MVP'),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    final qc = context.qc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: qc.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '초기화하시겠습니까?',
          style: TextStyle(color: qc.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '모든 퀘스트 기록, 경험치, 스탯이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: qc.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소', style: TextStyle(color: qc.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AppState>().resetAll();
            },
            child: const Text('초기화', style: TextStyle(color: AppColors.crazy)),
          ),
        ],
      ),
    );
  }
}

class _ComfortOpt {
  final ComfortLevel zone;
  final String label;
  final String description;
  final Color color;
  const _ComfortOpt(this.zone, this.label, this.description, this.color);
}

const _comfortOptions = [
  _ComfortOpt(ComfortLevel.safe, 'SAFE', '평소와 거의 비슷하지만 조금 다른 행동', AppColors.safe),
  _ComfortOpt(ComfortLevel.normal, 'NORMAL', '확실히 새로운 경험', AppColors.normal),
  _ComfortOpt(ComfortLevel.challenge, 'CHALLENGE', '약간 불편하지만 해볼 만한 행동', AppColors.challenge),
  _ComfortOpt(ComfortLevel.crazy, 'CRAZY', '평소라면 절대 하지 않을 행동', AppColors.crazy),
];

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.qc.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  final ThemeMode currentMode;
  const _ThemeToggleTile({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    final isDark = currentMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: qc.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDark ? '다크 모드' : '라이트 모드',
                  style: TextStyle(
                    color: qc.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '화면 테마를 변경합니다',
                  style: TextStyle(color: qc.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (v) {
              context.read<AppState>().setThemeMode(
                    v ? ThemeMode.dark : ThemeMode.light,
                  );
            },
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ComfortOption extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ComfortOption({
    required this.label,
    required this.description,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : qc.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? color : qc.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? color : qc.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(color: qc.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback onTap;
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: qc.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDestructive ? AppColors.crazy : qc.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: qc.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: qc.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PremiumLockedTile extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  const _PremiumLockedTile({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;

    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: qc.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: qc.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: qc.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'PREMIUM',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: qc.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: qc.textSecondary, fontSize: 14)),
          Text(value, style: TextStyle(color: qc.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
