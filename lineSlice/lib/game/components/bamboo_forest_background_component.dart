import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// 1챕터 배경: 햇살이 비치는 대나무숲 오솔길. 소실점(숲 안쪽)에서 플레이어
/// 쪽으로 흙길이 넓어지고, 양옆엔 대나무가 늘어서 있으며, 나뭇잎 사이로
/// 비치는 햇살과 흩날리는 나뭇잎으로 속도감을 표현한다.
///
/// 장애물이 중앙(소실점)에서 좌우로 퍼지는 것과 같은 시각 언어를 공유해서
/// 화면 전체가 하나의 "다가오는 속도감"으로 읽히게 한다.
class BambooForestBackgroundComponent extends PositionComponent {
  BambooForestBackgroundComponent({required this.scrollSpeed, Random? random})
      : _random = random ?? Random(),
        super(priority: -10) {
    _leaves = List.generate(_leafCount, (_) => _Leaf.random(_random));
    _bambooSeeds = List.generate(_bambooCount, (_) => _random.nextDouble());
  }

  /// 길/나뭇잎이 흘러오는 체감 속도(px/s). 장애물 낙하 속도와 연동된다.
  double scrollSpeed;

  final Random _random;
  late final List<_Leaf> _leaves;
  late final List<double> _bambooSeeds;

  double _pathScrollT = 0;
  double _bambooScrollT = 0;
  double _sway = 0;

  static const Color _skyWarm = Color(0xFFFFF3D6);
  static const Color _skyMid = Color(0xFF9CC08A);
  static const Color _skyShade = Color(0xFF2F4A2E);
  static const Color _pathNear = Color(0xFF8A6A46);
  static const Color _pathFar = Color(0xFFC9A876);
  static const Color _bambooColor = Color(0xFF4C8C4A);
  static const Color _bambooDark = Color(0xFF335E33);
  static const Color _leafColor = Color(0xFF6FAF4E);
  static const Color _sunColor = Color(0xFFFFF7DD);

  static const int _bambooCount = 7;
  static const int _leafCount = 22;
  static const double _cycleRange = 1.25;

  double get horizonY => size.y * 0.10;
  double get _centerX => size.x / 2;
  Offset get _vanishingPoint => Offset(_centerX, horizonY);
  double get _pathTopHalfWidth => size.x * 0.035;
  double get _pathBottomHalfWidth => size.x * 0.56;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final travelPerSecond = scrollSpeed / (size.y - horizonY).clamp(1, double.infinity);
    _pathScrollT = (_pathScrollT + travelPerSecond * dt) % _cycleRange;
    _bambooScrollT = (_bambooScrollT + travelPerSecond * 0.6 * dt) % _cycleRange;
    _sway += dt;
    for (final leaf in _leaves) {
      leaf.t = (leaf.t + travelPerSecond * leaf.speedFactor * dt) % _cycleRange;
    }
  }

  double _easeT(double t) => t * t;
  double _yAt(double tRaw) => horizonY + (size.y - horizonY) * tRaw;
  double _halfWidthAt(double t) =>
      _pathTopHalfWidth + (_pathBottomHalfWidth - _pathTopHalfWidth) * _easeT(t);

  @override
  void render(Canvas canvas) {
    final vp = _vanishingPoint;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..shader = Gradient.radial(
          vp,
          size.y * 1.05,
          [_skyWarm, _skyMid, _skyShade],
          [0.0, 0.4, 1.0],
        ),
    );

    _drawSunRays(canvas, vp);
    _drawBamboo(canvas);
    _drawPath(canvas);
    _drawLeaves(canvas);
    _drawSunGlow(canvas, vp);
  }

  void _drawSunRays(Canvas canvas, Offset vp) {
    const rayCount = 9;
    final targetY = size.y * 1.05;
    final halfSpread = size.x * 0.6;
    for (int i = 0; i < rayCount; i++) {
      final frac = i / (rayCount - 1);
      final xOffset = (frac * 2 - 1) * halfSpread;
      final end = Offset(_centerX + xOffset, targetY);
      final paint = Paint()
        ..strokeWidth = size.x * 0.05
        ..shader = Gradient.linear(
          vp,
          end,
          [_sunColor.withValues(alpha: 0.22), _sunColor.withValues(alpha: 0.0)],
        );
      canvas.drawLine(vp, end, paint);
    }
  }

  void _drawBamboo(Canvas canvas) {
    for (final side in [-1.0, 1.0]) {
      for (int i = 0; i < _bambooCount; i++) {
        final tRaw = ((i / _bambooCount) + _bambooScrollT) % _cycleRange;
        final t = tRaw.clamp(0.0, 1.0);
        if (t <= 0.02) continue;
        final eased = _easeT(t);
        final y = _yAt(tRaw);
        final seed = _bambooSeeds[i];
        final baseX = _centerX + side * (size.x * 0.45 + size.x * 0.6 * eased);
        final stalkWidth = 4 + 20 * t;
        final stalkHeight = 60 + 300 * t;
        final swayOffset = sin(_sway * 0.8 + seed * 10) * (2 + 10 * t);
        final rect = Rect.fromLTWH(
          baseX - stalkWidth / 2 + swayOffset,
          y - stalkHeight,
          stalkWidth,
          stalkHeight,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(stalkWidth * 0.4)),
          Paint()..color = _bambooColor.withValues(alpha: 0.55 + 0.4 * t),
        );

        final nodePaint = Paint()
          ..color = _bambooDark.withValues(alpha: 0.6 + 0.3 * t)
          ..strokeWidth = max(0.6, stalkWidth * 0.12);
        for (final frac in [0.3, 0.6, 0.85]) {
          final ny = rect.top + rect.height * frac;
          canvas.drawLine(Offset(rect.left, ny), Offset(rect.right, ny), nodePaint);
        }

        final leafPaint = Paint()..color = _leafColor.withValues(alpha: 0.5 + 0.4 * t);
        final leafCenter = Offset(rect.center.dx, rect.top);
        canvas.drawOval(
          Rect.fromCenter(center: leafCenter, width: stalkWidth * 3.2, height: stalkWidth * 1.6),
          leafPaint,
        );
      }
    }
  }

  void _drawPath(Canvas canvas) {
    final path = Path()
      ..moveTo(_centerX - _pathTopHalfWidth, horizonY)
      ..lineTo(_centerX + _pathTopHalfWidth, horizonY)
      ..lineTo(_centerX + _pathBottomHalfWidth, size.y)
      ..lineTo(_centerX - _pathBottomHalfWidth, size.y)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(
          Offset(_centerX, horizonY),
          Offset(_centerX, size.y),
          [_pathFar, _pathNear],
        ),
    );

    // 낙엽/자국 패치로 흙길 질감을 더한다.
    for (int i = 0; i < 6; i++) {
      final tRaw = ((i / 6) + _pathScrollT) % _cycleRange;
      final t = tRaw.clamp(0.0, 1.0);
      if (t <= 0.02) continue;
      final y = _yAt(tRaw);
      final halfWidth = _halfWidthAt(t);
      final patchPaint = Paint()..color = const Color(0xFF6B4E32).withValues(alpha: 0.18 + 0.12 * t);
      final patchX = _centerX + (i.isEven ? -1 : 1) * halfWidth * 0.4;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(patchX, y), width: 10 + 40 * t, height: 4 + 12 * t),
        patchPaint,
      );
    }
  }

  void _drawLeaves(Canvas canvas) {
    for (final leaf in _leaves) {
      final tRaw = leaf.t;
      final t = tRaw.clamp(0.0, 1.0);
      final eased = _easeT(t);
      final x = _centerX + leaf.angleOffset * size.x * eased;
      final y = _yAt(tRaw);
      final r = 1.0 + 3.0 * t;
      final paint = Paint()..color = leaf.color.withValues(alpha: 0.2 + 0.6 * t);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(leaf.t * 6);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.8, height: r), paint);
      canvas.restore();
    }
  }

  void _drawSunGlow(Canvas canvas, Offset vp) {
    final glowRadius = size.x * 0.14;
    canvas.drawCircle(
      vp,
      glowRadius,
      Paint()
        ..shader = Gradient.radial(
          vp,
          glowRadius,
          [_sunColor.withValues(alpha: 0.85), _sunColor.withValues(alpha: 0.0)],
        ),
    );
  }
}

class _Leaf {
  _Leaf({required this.angleOffset, required this.t, required this.speedFactor, required this.color});

  final double angleOffset;
  final double speedFactor;
  final Color color;
  double t;

  static _Leaf random(Random random) {
    const colors = [Color(0xFF8BC34A), Color(0xFFDCE775), Color(0xFF6FAF4E), Color(0xFFC9A876)];
    return _Leaf(
      angleOffset: (random.nextDouble() * 2 - 1) * 0.9,
      t: random.nextDouble() * 1.25,
      speedFactor: 0.5 + random.nextDouble() * 0.7,
      color: colors[random.nextInt(colors.length)],
    );
  }
}
