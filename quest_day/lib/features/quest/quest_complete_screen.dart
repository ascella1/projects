import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/experience_entry.dart';
import '../../core/theme/app_theme.dart';

class QuestCompleteScreen extends StatefulWidget {
  final ExperienceEntry entry;
  const QuestCompleteScreen({super.key, required this.entry});

  @override
  State<QuestCompleteScreen> createState() => _QuestCompleteScreenState();
}

class _QuestCompleteScreenState extends State<QuestCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _xpAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4, curve: Curves.elasticOut)),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );
    _xpAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final qc = context.qc;

    return Scaffold(
      body: Stack(
        children: [
          const _SparkleBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        children: [
                          Text(entry.emoji, style: const TextStyle(fontSize: 72)),
                          const SizedBox(height: 20),
                          const Text(
                            'QUEST COMPLETE!',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fade,
                    child: Text(
                      '"${entry.title}"를 완료했습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: qc.textSecondary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _xpAnim,
                    builder: (ctx, _) => _XPCard(
                      xp: (entry.xpEarned * _xpAnim.value).round(),
                      statBoosts: entry.statBoosts,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _xpAnim,
                    child: _CollectionUnlock(entry: entry),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _xpAnim,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
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

class _XPCard extends StatelessWidget {
  final int xp;
  final Map<String, int> statBoosts;
  const _XPCard({required this.xp, required this.statBoosts});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: qc.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '+$xp XP',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (statBoosts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: qc.divider),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: statBoosts.entries.map((e) => _StatChip(stat: e.key, value: e.value)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String stat;
  final int value;
  const _StatChip({required this.stat, required this.value});

  Color get _color {
    switch (stat) {
      case 'exploration': return AppColors.exploration;
      case 'social': return AppColors.social;
      case 'courage': return AppColors.challenge;
      case 'creativity': return AppColors.creative;
      case 'spontaneity': return AppColors.random;
      case 'adaptability': return AppColors.thinking;
      default: return AppColors.primary;
    }
  }

  String get _label {
    switch (stat) {
      case 'exploration': return '탐험';
      case 'social': return '사교';
      case 'courage': return '용기';
      case 'creativity': return '창의';
      case 'spontaneity': return '즉흥';
      case 'adaptability': return '적응력';
      case 'action': return '행동력';
      case 'thinking': return '사고력';
      case 'relationship': return '관계';
      default: return stat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$_label +$value',
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CollectionUnlock extends StatelessWidget {
  final ExperienceEntry entry;
  const _CollectionUnlock({required this.entry});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${entry.number.toString().padLeft(3, '0')}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEW EXPERIENCE UNLOCKED',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.title,
                  style: TextStyle(
                    color: qc.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkleBackground extends StatefulWidget {
  const _SparkleBackground();

  @override
  State<_SparkleBackground> createState() => _SparkleBackgroundState();
}

class _SparkleBackgroundState extends State<_SparkleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = Random();
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(_rng));
    }
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) => CustomPaint(
        size: Size.infinite,
        painter: _ParticlePainter(_particles, _ctrl.value),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;
  _Particle(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = 2 + rng.nextDouble() * 3,
        speed = 0.5 + rng.nextDouble() * 0.5,
        phase = rng.nextDouble() * 2 * 3.14159;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final opacity = (sin(progress * 2 * 3.14159 * p.speed + p.phase) + 1) / 2;
      paint.color = AppColors.accent.withValues(alpha: opacity * 0.4);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
