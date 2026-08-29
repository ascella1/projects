import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../models/obstacle_material.dart';

/// 도로의 소실점(화면 중앙 상단) 근처에서 작게 생성되어, 플레이어 쪽(화면
/// 하단)으로 다가올수록 커지면서 좌우로 퍼져나가는 대나무 장애물. 배경(대나무숲)
/// 과 같은 시각 언어(중앙에서 좌우로 확산)를 공유한다.
///
/// 절단 판정은 Flame 충돌 시스템이 아니라, 스와이프 궤적(선분)과
/// [hitRect] 사각형의 교차 여부를 매 프레임 직접 계산해서 판정한다.
/// 지금은 도형으로 종류를 구분하고, 나중에 [spriteAssetPath]를 채우면
/// 이미지로 교체할 수 있게 구조만 잡아둔다.
class ObstacleComponent extends PositionComponent {
  ObstacleComponent({
    required this.material,
    required this.spawnX,
    required this.targetX,
    required double spawnY,
    required this.fallSpeed,
    required this.growthStartY,
    required this.growthEndY,
    this.spriteAssetPath,
    Random? random,
  })  : _random = random ?? Random(),
        super(position: Vector2(spawnX, spawnY), anchor: Anchor.center) {
    size = Vector2.all(_baseSize * _progressAt(spawnY));
    _spinDirection = _random.nextBool() ? 1.0 : -1.0;
    _spinSpeed = 0.5 + _random.nextDouble() * 0.5;
    _rotationOffset = _random.nextDouble() * pi * 2;
    _leafSide = _random.nextBool() ? 1.0 : -1.0;
  }

  final ObstacleMaterial material;
  final double fallSpeed;
  final Random _random;

  /// 소실점 부근의 시작 x(보통 도로 중앙)와, 미스 라인에 도달했을 때의 최종 x.
  /// 배경의 대나무/길과 같은 이징(t^2)으로 중앙에서 좌우로 퍼진다.
  final double spawnX;
  final double targetX;

  /// 이 y좌표에서는 [_minScale] 크기/중앙(spawnX)에서, [growthEndY]에서는
  /// 원래 크기(1.0배)/최종 위치(targetX)가 되도록 보간한다.
  final double growthStartY;
  final double growthEndY;

  /// 나중에 실제 장애물 이미지를 쓸 때 채워 넣을 에셋 경로. 지금은 미사용.
  final String? spriteAssetPath;

  static const double _baseSize = 46;
  static const double _minScale = 0.22;

  double _age = 0;
  late final double _spinDirection;
  late final double _spinSpeed;
  late final double _rotationOffset;
  late final double _leafSide;

  double _progressAt(double y) {
    final range = growthEndY - growthStartY;
    return range == 0 ? 1.0 : ((y - growthStartY) / range).clamp(0.0, 1.0);
  }

  double _easeT(double t) => t * t;

  Rect get hitRect => Rect.fromLTWH(
        position.x - size.x / 2,
        position.y - size.y / 2,
        size.x,
        size.y,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y += fallSpeed * dt;
    final t = _progressAt(position.y);
    final eased = _easeT(t);
    position.x = spawnX + (targetX - spawnX) * eased;
    size = Vector2.all(_baseSize * (_minScale + (1 - _minScale) * t));
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final rotation = _rotationOffset + _age * _spinSpeed * _spinDirection;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    _renderBambooSegment(canvas);
    if (material == ObstacleMaterial.goldenBamboo) {
      _drawGoldGlow(canvas);
    }

    canvas.restore();
  }

  void _renderBambooSegment(Canvas canvas) {
    final rect = Rect.fromLTWH(size.x * 0.24, 0, size.x * 0.52, size.y);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.18));

    final darkShade = material == ObstacleMaterial.shoot
        ? const Color(0xFF6B9A3F)
        : material == ObstacleMaterial.bamboo
            ? const Color(0xFF2C5A2A)
            : const Color(0xFFB8862E);

    final fill = Paint()
      ..shader = Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [material.color, darkShade],
      );
    canvas.drawRRect(rrect, fill);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, size.x * 0.03)
      ..color = darkShade;
    canvas.drawRRect(rrect, outline);

    final nodePaint = Paint()
      ..color = darkShade.withValues(alpha: 0.85)
      ..strokeWidth = max(1.0, size.y * 0.05);
    for (final frac in [0.32, 0.68]) {
      final y = rect.top + rect.height * frac;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), nodePaint);
    }

    final fiberPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.18)
      ..strokeWidth = max(0.6, size.x * 0.015);
    canvas.drawLine(
      Offset(rect.left + rect.width * 0.3, rect.top + 2),
      Offset(rect.left + rect.width * 0.3, rect.bottom - 2),
      fiberPaint,
    );

    final leafCenter = Offset(
      _leafSide > 0 ? rect.right : rect.left,
      rect.top + rect.height * 0.12,
    );
    final leafPaint = Paint()..color = material.color.withValues(alpha: 0.9);
    canvas.save();
    canvas.translate(leafCenter.dx, leafCenter.dy);
    canvas.rotate(_leafSide > 0 ? -0.5 : 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.x * 0.42, height: size.x * 0.16),
      leafPaint,
    );
    canvas.restore();
  }

  void _drawGoldGlow(Canvas canvas) {
    final rect = Rect.fromLTWH(size.x * 0.24, 0, size.x * 0.52, size.y);
    final glow = Paint()
      ..color = material.color.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, max(2.0, size.x * 0.12));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.18)), glow);
  }
}
