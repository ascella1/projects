import 'package:flame/components.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart';

/// 크리티컬 등 강한 임팩트 순간에 화면 전체를 살짝 번쩍이는 연출.
/// 게임에 하나만 두고 [flash]로 재사용한다.
class ScreenFlashComponent extends PositionComponent {
  ScreenFlashComponent() : super(priority: 100);

  Color? _color;
  double _duration = 0.15;
  double _peakAlpha = 0.5;
  double _t = 0;

  void flash(Color color, {double duration = 0.15, double peakAlpha = 0.5}) {
    _color = color;
    _duration = duration;
    _peakAlpha = peakAlpha;
    _t = 0;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_color == null) return;
    _t += dt;
    if (_t >= _duration) {
      _color = null;
    }
  }

  @override
  void render(Canvas canvas) {
    final color = _color;
    if (color == null) return;
    final progress = (_t / _duration).clamp(0.0, 1.0);
    final alpha = (1.0 - Curves.easeOut.transform(progress)) * _peakAlpha;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = color.withValues(alpha: alpha),
    );
  }
}
