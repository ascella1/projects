import 'dart:ui';

import 'package:flame/components.dart';

/// 스와이프 궤적을 잠깐 보여주는 잔상. 입력에 대한 즉각적인 시각 피드백용.
class SwipeTrailComponent extends PositionComponent {
  final List<Vector2> _points = [];
  double _fadeTimer = 0;
  static const double _fadeDuration = 0.2;
  bool _finished = false;

  void addPoint(Vector2 point) {
    _points.add(point.clone());
  }

  void finish() {
    _finished = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished) {
      _fadeTimer += dt;
      if (_fadeTimer >= _fadeDuration) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_points.length < 2) return;
    final alpha = _finished ? (1 - _fadeTimer / _fadeDuration).clamp(0.0, 1.0) : 1.0;
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, 0.85 * alpha)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(_points.first.x, _points.first.y);
    for (final p in _points.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    canvas.drawPath(path, paint);
  }
}
