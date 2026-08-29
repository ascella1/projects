import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

class _Shard {
  _Shard({
    required this.offset,
    required this.velocity,
    required this.rotationSpeed,
    required this.size,
  });

  Offset offset;
  Offset velocity;
  double rotation = 0;
  final double rotationSpeed;
  final double size;
  double life = 1.0;
}

/// 절단 성공 시 단면을 따라 쪼개지는 파편 파티클. 크리티컬이면 확산 범위와
/// 개수가 3배가 된다 (스펙 4번).
class SliceParticleComponent extends PositionComponent {
  SliceParticleComponent({
    required Vector2 position,
    required this.color,
    required Vector2 cutDirection,
    this.isCritical = false,
    Random? random,
  })  : _random = random ?? Random(),
        _cutDirection = cutDirection.length == 0
            ? Vector2(1, 0)
            : cutDirection.normalized(),
        super(position: position, anchor: Anchor.center) {
    final count = isCritical ? 18 : 6;
    final spreadMultiplier = isCritical ? 3.0 : 1.0;
    _shards = List.generate(count, (_) => _makeShard(spreadMultiplier));
  }

  final Color color;
  final bool isCritical;
  final Vector2 _cutDirection;
  final Random _random;
  late final List<_Shard> _shards;

  static const double _lifeSpan = 0.45;

  _Shard _makeShard(double spreadMultiplier) {
    // 절단선에 수직인 방향으로 주로 퍼지도록 한다.
    final perpendicular = Vector2(-_cutDirection.y, _cutDirection.x);
    final side = _random.nextBool() ? 1.0 : -1.0;
    final spread = perpendicular * side * (60 + _random.nextDouble() * 120) *
        spreadMultiplier;
    final along = _cutDirection * (_random.nextDouble() * 40 - 20);
    return _Shard(
      offset: Offset.zero,
      velocity: Offset(spread.x + along.x, spread.y + along.y),
      rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      size: 3 + _random.nextDouble() * 5,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final shard in _shards) {
      shard.offset += shard.velocity * dt;
      shard.velocity = shard.velocity * 0.92;
      shard.rotation += shard.rotationSpeed * dt;
      shard.life -= dt / _lifeSpan;
    }
    _shards.removeWhere((s) => s.life <= 0);
    if (_shards.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final shard in _shards) {
      final paint = Paint()
        ..color = color.withValues(alpha: shard.life.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(shard.offset.dx, shard.offset.dy);
      canvas.rotate(shard.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: shard.size, height: shard.size * 1.6),
        paint,
      );
      canvas.restore();
    }
  }
}
