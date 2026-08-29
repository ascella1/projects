import 'dart:ui';

import 'package:flame/components.dart';

/// 절단 시 드랍되는 XP 젬. 생성 즉시 플레이어 쪽으로 강하게 가속하며
/// 빠르게 흡수된다 (스펙 3번/5번).
class XpGemComponent extends PositionComponent {
  XpGemComponent({
    required Vector2 position,
    required this.xpValue,
    required this.getPlayerPosition,
    required this.onCollected,
  }) : super(position: position, anchor: Anchor.center, size: Vector2.all(14));

  final int xpValue;
  final Vector2 Function() getPlayerPosition;
  final void Function(int xp) onCollected;

  static const double _initialSpeed = 260;
  static const double _acceleration = 2400;
  static const double _absorbDistance = 20;

  double _speed = _initialSpeed;

  @override
  void update(double dt) {
    super.update(dt);
    final playerPos = getPlayerPosition();
    final toPlayer = playerPos - position;
    final distance = toPlayer.length;

    _speed += _acceleration * dt;
    final direction = toPlayer / (distance == 0 ? 1 : distance);
    position += direction * _speed * dt;

    if (distance <= _absorbDistance) {
      onCollected(xpValue);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFD54F);
    final glow = Paint()..color = const Color(0x66FFD54F);
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2 + 3, glow);
    canvas.drawCircle(center, size.x / 2, paint);
  }
}
