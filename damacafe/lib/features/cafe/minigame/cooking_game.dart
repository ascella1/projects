import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// 요리 미니게임: 좌우로 움직이는 마커가 목표 구간(초록색)에 있을 때 탭하면 성공.
/// 실패해도 페널티 없이 계속 다시 시도할 수 있다 (처벌보다 재미 강조).
class CookingGame extends FlameGame with TapCallbacks {
  CookingGame({required this.onSuccess});

  final VoidCallback onSuccess;

  late RectangleComponent _track;
  late RectangleComponent _targetZone;
  late CircleComponent _marker;

  double _direction = 1;
  static const double _speed = 220;
  static const double _edgeMargin = 20;

  @override
  Future<void> onLoad() async {
    final trackWidth = size.x - _edgeMargin * 2;
    final trackY = size.y / 2;

    _track = RectangleComponent(
      position: Vector2(_edgeMargin, trackY - 10),
      size: Vector2(trackWidth, 20),
      paint: Paint()..color = const Color(0xFFEFE6D9),
    );

    _targetZone = RectangleComponent(
      position: Vector2(_edgeMargin + trackWidth * 0.4, trackY - 10),
      size: Vector2(trackWidth * 0.2, 20),
      paint: Paint()..color = const Color(0xFF85C1A3),
    );

    _marker = CircleComponent(
      radius: 14,
      position: Vector2(_edgeMargin, trackY),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFE8A87C),
    );

    addAll([_track, _targetZone, _marker]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final trackLeft = _edgeMargin;
    final trackRight = size.x - _edgeMargin;
    _marker.position.x += _speed * _direction * dt;
    if (_marker.position.x >= trackRight) {
      _marker.position.x = trackRight;
      _direction = -1;
    } else if (_marker.position.x <= trackLeft) {
      _marker.position.x = trackLeft;
      _direction = 1;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final markerX = _marker.position.x;
    final zoneLeft = _targetZone.position.x;
    final zoneRight = zoneLeft + _targetZone.size.x;
    if (markerX >= zoneLeft && markerX <= zoneRight) {
      onSuccess();
    }
  }
}
