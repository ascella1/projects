import 'package:flame/components.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart';

/// 절단 지점에서 퍼지는 충격파 링. 타격감을 강화하는 짧은 시각 효과.
class ShockwaveRingComponent extends PositionComponent {
  ShockwaveRingComponent({
    required Vector2 position,
    required this.color,
    this.maxRadius = 60,
    this.duration = 0.35,
  }) : super(position: position, anchor: Anchor.center);

  final Color color;
  final double maxRadius;
  final double duration;

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_t / duration).clamp(0.0, 1.0);
    final radius = maxRadius * Curves.easeOut.transform(progress);
    final alpha = 1.0 - progress;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (1 - progress) + 1
      ..color = color.withValues(alpha: alpha * 0.85);
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}
