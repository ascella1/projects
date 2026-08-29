import 'package:flame/extensions.dart';

/// 스와이프 궤적(선분)과 장애물 히트박스(사각형) 교차 판정에 쓰이는 기하 유틸.
class Geometry {
  Geometry._();

  /// 선분 [p1]-[p2]가 사각형 [rect]와 교차하거나, 두 점 중 하나라도
  /// 사각형 내부에 있으면 true.
  static bool segmentIntersectsRect(Vector2 p1, Vector2 p2, Rect rect) {
    if (rect.contains(p1.toOffset()) || rect.contains(p2.toOffset())) {
      return true;
    }

    final topLeft = Vector2(rect.left, rect.top);
    final topRight = Vector2(rect.right, rect.top);
    final bottomRight = Vector2(rect.right, rect.bottom);
    final bottomLeft = Vector2(rect.left, rect.bottom);

    return _segmentsIntersect(p1, p2, topLeft, topRight) ||
        _segmentsIntersect(p1, p2, topRight, bottomRight) ||
        _segmentsIntersect(p1, p2, bottomRight, bottomLeft) ||
        _segmentsIntersect(p1, p2, bottomLeft, topLeft);
  }

  static double _cross(Vector2 o, Vector2 a, Vector2 b) {
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
  }

  static bool _onSegment(Vector2 p, Vector2 q, Vector2 r) {
    return q.x <= (p.x > r.x ? p.x : r.x) &&
        q.x >= (p.x < r.x ? p.x : r.x) &&
        q.y <= (p.y > r.y ? p.y : r.y) &&
        q.y >= (p.y < r.y ? p.y : r.y);
  }

  static bool _segmentsIntersect(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4) {
    final d1 = _cross(p3, p4, p1);
    final d2 = _cross(p3, p4, p2);
    final d3 = _cross(p1, p2, p3);
    final d4 = _cross(p1, p2, p4);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }

    if (d1 == 0 && _onSegment(p3, p1, p4)) return true;
    if (d2 == 0 && _onSegment(p3, p2, p4)) return true;
    if (d3 == 0 && _onSegment(p1, p3, p2)) return true;
    if (d4 == 0 && _onSegment(p1, p4, p2)) return true;

    return false;
  }
}
