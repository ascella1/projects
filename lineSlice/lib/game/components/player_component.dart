import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// 플레이어 캐릭터. 좌우 이동 없이 화면 하단 고정 위치에서 자동 전진하는
/// 느낌만 표현한다 (스펙 3번: 캐릭터 자동 전진, 좌우 이동 없음, 화면 고정 시점).
///
/// 1챕터(대나무숲) 컨셉에 맞춰 삿갓을 쓴 나그네가 뒷모습으로 달려가는
/// 실루엣을 표현한다. 나중에 [spriteAssetPath]를 채워 넣으면 이미지로
/// 교체할 수 있도록 구조만 잡아둔다.
class PlayerComponent extends PositionComponent {
  PlayerComponent({this.spriteAssetPath}) : super(anchor: Anchor.center);

  /// 나중에 실제 캐릭터 이미지를 쓸 때 채워 넣을 에셋 경로. 지금은 미사용.
  final String? spriteAssetPath;

  static const Color _robeDark = Color(0xFF2E2A24);
  static const Color _robeMid = Color(0xFF4A4238);
  static const Color _sash = Color(0xFFB5502A);
  static const Color _hat = Color(0xFFC9A876);
  static const Color _hatDark = Color(0xFF8A6A46);

  double _runPhase = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2(48, 78);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _runPhase += dt * 9;
  }

  @override
  void render(Canvas canvas) {
    final stride = math.sin(_runPhase);
    final bob = math.sin(_runPhase * 2).abs() * 2.5;
    final w = size.x;
    final h = size.y;
    final cx = w / 2;

    final dark = Paint()..color = _robeDark;
    final mid = Paint()..color = _robeMid;
    final sash = Paint()..color = _sash;

    // 뒤에서 교차로 흔들리는 다리.
    final legSwing = stride * (h * 0.16);
    for (final side in [-1.0, 1.0]) {
      final swing = side > 0 ? legSwing : -legSwing;
      final legRect = Rect.fromLTWH(cx + side * w * 0.14 - w * 0.09, h * 0.52 - bob, w * 0.16, h * 0.46);
      canvas.save();
      canvas.translate(0, swing * 0.3);
      canvas.drawRRect(RRect.fromRectAndRadius(legRect, Radius.circular(w * 0.06)), dark);
      canvas.restore();
    }

    // 몸통 (헐렁한 두루마기 실루엣).
    final torso = Path()
      ..moveTo(cx - w * 0.24, h * 0.22 - bob)
      ..lineTo(cx + w * 0.24, h * 0.22 - bob)
      ..lineTo(cx + w * 0.34, h * 0.58 - bob)
      ..lineTo(cx - w * 0.34, h * 0.58 - bob)
      ..close();
    canvas.drawPath(torso, mid);

    // 허리 새시(대비 포인트 컬러).
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.28, h * 0.42 - bob, w * 0.56, h * 0.06),
      sash,
    );

    // 어깨 라인.
    for (final side in [-1.0, 1.0]) {
      final shoulder = Rect.fromCenter(
        center: Offset(cx + side * w * 0.28, h * 0.23 - bob),
        width: w * 0.18,
        height: h * 0.1,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(shoulder, Radius.circular(w * 0.04)), mid);
    }

    // 머리.
    final headCenter = Offset(cx, h * 0.14 - bob);
    final headRadius = w * 0.15;
    canvas.drawCircle(headCenter, headRadius, Paint()..color = const Color(0xFF3A2E22));

    // 삿갓(대나무 모자) - 원뿔 + 챙.
    final hatBrimCenter = Offset(cx, h * 0.08 - bob);
    canvas.drawOval(
      Rect.fromCenter(center: hatBrimCenter, width: w * 0.62, height: h * 0.09),
      Paint()..color = _hatDark,
    );
    final hatPath = Path()
      ..moveTo(hatBrimCenter.dx - w * 0.26, hatBrimCenter.dy)
      ..lineTo(cx, hatBrimCenter.dy - h * 0.16)
      ..lineTo(hatBrimCenter.dx + w * 0.26, hatBrimCenter.dy)
      ..close();
    canvas.drawPath(hatPath, Paint()..color = _hat);
    canvas.drawPath(
      hatPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _hatDark,
    );

    // 팔.
    for (final side in [-1.0, 1.0]) {
      final swing = side > 0 ? -legSwing : legSwing;
      final armStart = Offset(cx + side * w * 0.28, h * 0.26 - bob);
      final armEnd = Offset(cx + side * w * 0.32, h * 0.5 - bob + swing * 0.4);
      canvas.drawLine(
        armStart,
        armEnd,
        Paint()
          ..color = _robeDark
          ..strokeWidth = w * 0.1
          ..strokeCap = StrokeCap.round,
      );
    }

    // 발 밑 그림자(달리는 접지감).
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.98), width: w * 0.5, height: h * 0.05),
      Paint()..color = const Color(0x33241A10),
    );
  }
}
