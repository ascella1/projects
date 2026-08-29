import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart';

/// 절단할 때마다 화면 중앙에 "COMBO n"을 잠깐 크게 띄워주는 피드백.
/// 매번 새 컴포넌트를 만들지 않고 하나를 재사용하며 애니메이션 타이머만
/// 리셋한다.
class ComboPopupComponent extends PositionComponent {
  ComboPopupComponent() : super(anchor: Anchor.center);

  static const double _duration = 0.7;
  static const double _popInEnd = 0.22;
  static const double _fadeStart = 0.45;

  int? _combo;
  double _animTime = 0;

  void trigger(int combo) {
    _combo = combo;
    _animTime = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_combo == null) return;
    _animTime += dt;
    if (_animTime >= _duration) {
      _combo = null;
    }
  }

  @override
  void render(Canvas canvas) {
    final combo = _combo;
    if (combo == null) return;

    final popT = (_animTime / _popInEnd).clamp(0.0, 1.0);
    final scale = 0.35 + Curves.easeOutBack.transform(popT) * 0.75;

    final fadeT = ((_animTime - _fadeStart) / (_duration - _fadeStart)).clamp(0.0, 1.0);
    final alpha = 1.0 - Curves.easeIn.transform(fadeT);
    if (alpha <= 0) return;

    final fontSize = 30 + min(combo, 12) * 2.5;
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'COMBO $combo',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Color.fromRGBO(255, 213, 79, alpha),
          shadows: [
            Shadow(color: Color.fromRGBO(0, 0, 0, alpha * 0.7), blurRadius: 10),
            Shadow(color: Color.fromRGBO(255, 213, 79, alpha * 0.5), blurRadius: 18),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.scale(scale);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }
}
