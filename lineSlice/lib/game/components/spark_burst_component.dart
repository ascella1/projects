import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class _Spark {
  _Spark({required this.velocity, required this.radius});

  Offset velocity;
  Offset offset = Offset.zero;
  final double radius;
  double life = 1.0;
}

/// 절단/크리티컬 시 사방으로 튀는 불꽃놀이 스파크. [SliceParticleComponent]의
/// 단면 파편과 별개로, 훨씬 화려하고 즉각적인 "터지는" 느낌을 더한다.
class SparkBurstComponent extends PositionComponent {
  SparkBurstComponent({
    required Vector2 position,
    required this.colors,
    int count = 18,
    double speedMultiplier = 1.0,
    Random? random,
  })  : _random = random ?? Random(),
        super(position: position, anchor: Anchor.center) {
    _sparks = List.generate(count, (_) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = (140 + _random.nextDouble() * 220) * speedMultiplier;
      return _Spark(
        velocity: Offset(cos(angle), sin(angle)) * speed,
        radius: 1.5 + _random.nextDouble() * 2.5,
      );
    });
    _sparkColors = List.generate(_sparks.length, (_) => colors[_random.nextInt(colors.length)]);
  }

  final List<Color> colors;
  final Random _random;
  late final List<_Spark> _sparks;
  late final List<Color> _sparkColors;

  static const double _lifeSpan = 0.55;
  static const double _gravity = 340;
  static const double _drag = 0.94;

  @override
  void update(double dt) {
    super.update(dt);
    for (final spark in _sparks) {
      spark.offset += spark.velocity * dt;
      spark.velocity = Offset(spark.velocity.dx * _drag, spark.velocity.dy * _drag + _gravity * dt);
      spark.life -= dt / _lifeSpan;
    }
    if (_sparks.every((s) => s.life <= 0)) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _sparks.length; i++) {
      final spark = _sparks[i];
      if (spark.life <= 0) continue;
      final alpha = spark.life.clamp(0.0, 1.0);
      final color = _sparkColors[i];

      final glow = Paint()
        ..color = color.withValues(alpha: alpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(spark.offset, spark.radius * 2.2, glow);

      final core = Paint()..color = color.withValues(alpha: alpha);
      canvas.drawCircle(spark.offset, spark.radius, core);
    }
  }
}
