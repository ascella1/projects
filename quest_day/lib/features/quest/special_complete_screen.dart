import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/special_mission.dart';
import '../../core/theme/app_theme.dart';

class SpecialCompleteScreen extends StatefulWidget {
  final SpecialClaimResult result;
  final SpecialMission mission;

  const SpecialCompleteScreen({
    super.key,
    required this.result,
    required this.mission,
  });

  @override
  State<SpecialCompleteScreen> createState() => _SpecialCompleteScreenState();
}

class _SpecialCompleteScreenState extends State<SpecialCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _main;
  late AnimationController _confettiCtrl;

  late Animation<double> _flash;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _xpAnim;
  late Animation<double> _bottomAnim;

  final _rng = Random();
  late List<_Confetti> _confetti;

  bool get _isWinner => widget.result.isWinner;

  @override
  void initState() {
    super.initState();
    _confetti = List.generate(_isWinner ? 90 : 0, (_) => _Confetti(_rng));

    _main = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));

    _flash = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.75), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.0), weight: 22),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 70),
    ]).animate(_main);

    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: const Interval(0.06, 0.45, curve: Curves.elasticOut)),
    );
    _fadeAnim = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.05, 0.25, curve: Curves.easeOut),
    );
    _xpAnim = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.40, 0.70, curve: Curves.easeOut),
    );
    _bottomAnim = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.65, 0.90, curve: Curves.easeOut),
    );

    HapticFeedback.heavyImpact();
    _main.forward();
    if (_isWinner) _confettiCtrl.forward();
  }

  @override
  void dispose() {
    _main.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: qc.background,
      body: Stack(
        children: [
          // 컨페티 (승리 시만)
          if (_isWinner)
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (ctx, child) => CustomPaint(
                size: size,
                painter: _ConfettiPainter(_confetti, _confettiCtrl.value * 3.5),
              ),
            ),

          // 골든 플래시
          AnimatedBuilder(
            animation: _flash,
            builder: (ctx, child) => IgnorePointer(
              child: Container(
                color: (_isWinner ? const Color(0xFFFBBF24) : Colors.white)
                    .withValues(alpha: _flash.value),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 70),

                  // 이모지 + 타이틀
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Column(
                        children: [
                          Text(
                            _isWinner ? '🏆' : '😢',
                            style: const TextStyle(fontSize: 72),
                          ),
                          const SizedBox(height: 20),
                          if (_isWinner) ...[
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                              ).createShader(b),
                              child: const Text(
                                '전국 최초 완료!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '「${widget.mission.title}」',
                              style: TextStyle(
                                color: qc.textSecondary,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ] else ...[
                            Text(
                              '아쉽게도 누군가 먼저 했어요',
                              style: TextStyle(
                                color: qc.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '「${widget.mission.title}」',
                              style: TextStyle(
                                color: qc.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // XP 카드 (승리) / 위너 카드 (패배)
                  FadeTransition(
                    opacity: _xpAnim,
                    child: _isWinner
                        ? _WinnerXPCard(xp: widget.result.xpEarned)
                        : _LoserCard(winner: widget.result.winner),
                  ),

                  const Spacer(),

                  // 버튼
                  FadeTransition(
                    opacity: _bottomAnim,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isWinner ? AppColors.accent : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        child: Text(_isWinner ? '영광스럽다!' : '내일 더 빨리!'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 승리 XP 카드 ─────────────────────────────────────────────────────────────

class _WinnerXPCard extends StatelessWidget {
  final int xp;
  const _WinnerXPCard({required this.xp});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: qc.isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            '+$xp XP',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '스페셜 미션 보너스',
            style: TextStyle(color: context.qc.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── 패배 — 위너 정보 카드 ───────────────────────────────────────────────────

class _LoserCard extends StatelessWidget {
  final SpecialMissionClaim winner;
  const _LoserCard({required this.winner});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    final timeStr =
        '${winner.claimedAt.hour.toString().padLeft(2, '0')}:${winner.claimedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: qc.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: qc.divider),
      ),
      child: Column(
        children: [
          const Text('👑', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            winner.claimerNickname,
            style: TextStyle(
              color: qc.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '오늘 $timeStr에 완료했어요',
            style: TextStyle(color: qc.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            '내일 자정에 새 스페셜 미션이 열려요.\n더 빨리 도전하세요! 💪',
            textAlign: TextAlign.center,
            style: TextStyle(color: qc.textMuted, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─── 컨페티 (승리 시) ─────────────────────────────────────────────────────────

const _confettiColors = [
  Color(0xFFF59E0B), Color(0xFF7C3AED), Color(0xFFEC4899),
  Color(0xFF06B6D4), Color(0xFF10B981), Color(0xFFF97316),
  Color(0xFFFFFFFF), Color(0xFFA78BFA),
];

class _Confetti {
  final double sx, sy, vx, vy, rot0, rotS, size;
  final Color color;
  final bool isRect;
  final double delay;

  _Confetti(Random r)
      : sx = 0.35 + r.nextDouble() * 0.30,
        sy = 0.38 + r.nextDouble() * 0.10,
        vx = (r.nextDouble() - 0.5) * 1400,
        vy = -(r.nextDouble() * 900 + 300),
        rot0 = r.nextDouble() * pi * 2,
        rotS = (r.nextDouble() - 0.5) * 14,
        size = 5 + r.nextDouble() * 9,
        color = _confettiColors[r.nextInt(_confettiColors.length)],
        isRect = r.nextBool(),
        delay = r.nextDouble() * 0.18;

  Offset posAt(double t, Size s) {
    final dt = (t - delay).clamp(0.0, double.infinity);
    return Offset(sx * s.width + vx * dt, sy * s.height + vy * dt + 0.5 * 2200 * dt * dt);
  }

  double rotAt(double t) => rot0 + rotS * (t - delay).clamp(0.0, double.infinity);

  double opacityAt(double t) {
    if (t < delay) return 0;
    final dt = t - delay;
    if (dt < 0.08) return dt / 0.08;
    if (dt < 1.6) return 1.0;
    return (1.0 - (dt - 1.6) / 0.8).clamp(0.0, 1.0);
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> particles;
  final double t;
  const _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final opacity = p.opacityAt(t);
      if (opacity <= 0) continue;
      final pos = p.posAt(t, size);
      if (pos.dy > size.height + 40) continue;
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotAt(t));
      if (p.isRect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.45),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.48, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
