import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

// ─── 컨페티 색상 팔레트 ───────────────────────────────────────────────────────
const _confettiColors = [
  Color(0xFFF59E0B), // gold
  Color(0xFF7C3AED), // purple
  Color(0xFFEC4899), // pink
  Color(0xFF06B6D4), // cyan
  Color(0xFF10B981), // green
  Color(0xFFF97316), // orange
  Color(0xFFFFFFFF), // white
  Color(0xFFA78BFA), // lavender
];

class _Confetti {
  final double startX; // 0..1 relative
  final double startY;
  final double vx;     // px/s
  final double vy;     // px/s (negative = up)
  final double rot0;
  final double rotSpeed;
  final Color color;
  final double size;
  final bool isRect;
  final double delay;  // seconds

  _Confetti(Random rng)
      : startX = 0.35 + rng.nextDouble() * 0.30,
        startY = 0.42 + rng.nextDouble() * 0.10,
        vx = (rng.nextDouble() - 0.5) * 1400,
        vy = -(rng.nextDouble() * 900 + 300),
        rot0 = rng.nextDouble() * pi * 2,
        rotSpeed = (rng.nextDouble() - 0.5) * 14,
        color = _confettiColors[rng.nextInt(_confettiColors.length)],
        size = 5 + rng.nextDouble() * 9,
        isRect = rng.nextBool(),
        delay = rng.nextDouble() * 0.18;

  Offset posAt(double t, Size screen) {
    final dt = (t - delay).clamp(0.0, double.infinity);
    return Offset(
      startX * screen.width + vx * dt,
      startY * screen.height + vy * dt + 0.5 * 2200 * dt * dt,
    );
  }

  double rotAt(double t) => rot0 + rotSpeed * (t - delay).clamp(0.0, double.infinity);

  double opacityAt(double t) {
    if (t < delay) return 0;
    final dt = t - delay;
    if (dt < 0.08) return dt / 0.08;
    if (dt < 1.6) return 1.0;
    return (1.0 - (dt - 1.6) / 0.8).clamp(0.0, 1.0);
  }
}

class LevelUpScreen extends StatefulWidget {
  final int newLevel;
  final String? newTitle;
  const LevelUpScreen({super.key, required this.newLevel, this.newTitle});

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen>
    with TickerProviderStateMixin {
  // 메인 시퀀스 (2.8초)
  late AnimationController _main;
  // 컨페티 물리 (3.5초)
  late AnimationController _confettiCtrl;
  // 배경 별 반복
  late AnimationController _bgCtrl;

  late Animation<double> _flash;
  late Animation<double> _shockwave;
  late Animation<double> _shockwaveOpacity;
  late Animation<double> _levelScale;
  late Animation<double> _levelFade;
  late Animation<double> _headerFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _buttonFade;

  final _rng = Random();
  late List<_Confetti> _confetti;

  @override
  void initState() {
    super.initState();

    _confetti = List.generate(90, (_) => _Confetti(_rng));

    _main = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // 플래시: 0 → peak(0.06) → fade(0.25)
    _flash = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.85), weight: 6),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.0), weight: 19),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 75),
    ]).animate(_main);

    // 충격파 링: 반지름 0 → 1 (0.04~0.38)
    _shockwave = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _main, curve: const Interval(0.04, 0.38, curve: Curves.easeOut)),
    );
    _shockwaveOpacity = Tween<double>(begin: 0.9, end: 0.0).animate(
      CurvedAnimation(parent: _main, curve: const Interval(0.04, 0.38, curve: Curves.easeIn)),
    );

    // 레벨 배지
    _levelScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: const Interval(0.06, 0.42, curve: Curves.elasticOut)),
    );
    _levelFade = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.06, 0.20, curve: Curves.easeOut),
    );

    // "LEVEL UP!" + 서브텍스트
    _headerFade = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.32, 0.52, curve: Curves.easeOut),
    );

    // 칭호 카드 슬라이드업
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(parent: _main, curve: const Interval(0.58, 0.82, curve: Curves.easeOutBack)),
    );
    _titleFade = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.58, 0.78, curve: Curves.easeOut),
    );

    // 버튼
    _buttonFade = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
    );

    // 햅틱 → 애니메이션 시작
    HapticFeedback.heavyImpact();
    _main.forward();
    _confettiCtrl.forward();
  }

  @override
  void dispose() {
    _main.dispose();
    _confettiCtrl.dispose();
    _bgCtrl.dispose();
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
          // 배경 별
          _BgStars(ctrl: _bgCtrl),

          // 컨페티
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (context, child) {
              final t = _confettiCtrl.value * 3.5;
              return CustomPaint(
                size: size,
                painter: _ConfettiPainter(_confetti, t),
              );
            },
          ),

          // 충격파 링
          AnimatedBuilder(
            animation: _main,
            builder: (ctx, child) => CustomPaint(
              size: size,
              painter: _ShockwavePainter(
                cx: size.width / 2,
                cy: size.height * 0.46,
                progress: _shockwave.value,
                opacity: _shockwaveOpacity.value,
                maxRadius: size.width * 0.75,
              ),
            ),
          ),

          // 골든 플래시 오버레이
          AnimatedBuilder(
            animation: _flash,
            builder: (ctx, child) => IgnorePointer(
              child: Container(
                color: const Color(0xFFFBBF24).withValues(alpha: _flash.value),
              ),
            ),
          ),

          // UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // "LEVEL UP!" 텍스트
                  FadeTransition(
                    opacity: _headerFade,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFF7C3AED)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: const Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 레벨 배지 (글로우)
                  ScaleTransition(
                    scale: _levelScale,
                    child: FadeTransition(
                      opacity: _levelFade,
                      child: _GlowBadge(level: widget.newLevel),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 서브텍스트
                  FadeTransition(
                    opacity: _headerFade,
                    child: Text(
                      'LEVEL ${widget.newLevel} 달성!',
                      style: TextStyle(
                        color: qc.textSecondary,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 칭호 카드
                  if (widget.newTitle != null)
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: _TitleCard(title: widget.newTitle!),
                      ),
                    ),

                  const Spacer(),

                  // 버튼
                  FadeTransition(
                    opacity: _buttonFade,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
                        child: const Text('CONTINUE'),
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

// ─── 글로우 레벨 배지 ─────────────────────────────────────────────────────────

class _GlowBadge extends StatelessWidget {
  final int level;
  const _GlowBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF9D5CF6), Color(0xFF5B21B6)],
          stops: [0.3, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.7),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 80,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.25),
            blurRadius: 120,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 62,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Colors.white54, blurRadius: 20),
              Shadow(color: Color(0xFFFBBF24), blurRadius: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 칭호 카드 ────────────────────────────────────────────────────────────────

class _TitleCard extends StatelessWidget {
  final String title;
  const _TitleCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: qc.isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🏷️  새 칭호 획득!',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '「$title」',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: qc.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '캐릭터 화면에서 확인할 수 있어요',
            style: TextStyle(color: qc.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── 충격파 링 Painter ────────────────────────────────────────────────────────

class _ShockwavePainter extends CustomPainter {
  final double cx, cy, progress, opacity, maxRadius;
  const _ShockwavePainter({
    required this.cx,
    required this.cy,
    required this.progress,
    required this.opacity,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final r = progress * maxRadius;
    final strokeWidth = (1 - progress) * 12 + 1;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.accent.withValues(alpha: opacity * 0.9);
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // 안쪽 두 번째 링
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.5
      ..color = Colors.white.withValues(alpha: opacity * 0.5);
    if (r > 30) canvas.drawCircle(Offset(cx, cy), r * 0.6, paint2);
  }

  @override
  bool shouldRepaint(_ShockwavePainter old) => true;
}

// ─── 컨페티 Painter ───────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> particles;
  final double t; // elapsed seconds
  const _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final opacity = p.opacityAt(t);
      if (opacity <= 0) continue;

      final pos = p.posAt(t, size);
      // 화면 밖이면 skip
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

// ─── 배경 별 ─────────────────────────────────────────────────────────────────

class _BgStars extends StatelessWidget {
  final AnimationController ctrl;
  const _BgStars({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, child) => CustomPaint(
        size: Size.infinite,
        painter: _BgStarPainter(ctrl.value),
      ),
    );
  }
}

class _BgStarPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  static final _stars = List.generate(40, (_) => (
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    r: 0.8 + _rng.nextDouble() * 2.2,
    speed: 0.3 + _rng.nextDouble() * 0.7,
    phase: _rng.nextDouble() * 2 * pi,
    gold: _rng.nextDouble() > 0.55,
  ));

  const _BgStarPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in _stars) {
      final opacity = (sin(t * 2 * pi * s.speed + s.phase) + 1) / 2;
      paint.color = (s.gold ? AppColors.accent : AppColors.primaryLight)
          .withValues(alpha: opacity * 0.45);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, paint);
    }
  }

  @override
  bool shouldRepaint(_BgStarPainter old) => old.t != t;
}
