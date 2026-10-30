import 'dart:math' as math;

import 'point2.dart';

const double _epsilon = 1e-9;
const double _radToDeg = 180 / math.pi;

/// The unsigned angle in degrees at vertex [b], formed by `b->a` and `b->c`.
///
/// Returns `0` for a fully folded joint and `180` for a straight one.
/// Returns `null` when either segment has no length, so a degenerate frame
/// cannot poison downstream arithmetic with `NaN`.
double? angleAtVertex(Point2 a, Point2 b, Point2 c) {
  final double ax = a.x - b.x, ay = a.y - b.y;
  final double cx = c.x - b.x, cy = c.y - b.y;

  final magA = math.sqrt(ax * ax + ay * ay);
  final magC = math.sqrt(cx * cx + cy * cy);
  if (magA < _epsilon || magC < _epsilon) return null;

  // Clamped because float drift can push the quotient outside acos's domain
  // for near-collinear joints, which is common at the top of a rep.
  final cosine = ((ax * cx + ay * cy) / (magA * magC)).clamp(-1.0, 1.0);
  return math.acos(cosine) * _radToDeg;
}

/// The unsigned angle in degrees between the segment [from] -> [to] and
/// straight up the image.
///
/// `0` points up, `90` is horizontal, `180` points down. Leaning left and
/// leaning right give the same value; callers that need direction should
/// compare the x components themselves.
double? angleFromVertical(Point2 from, Point2 to) {
  final double dx = to.x - from.x, dy = to.y - from.y;
  final mag = math.sqrt(dx * dx + dy * dy);
  if (mag < _epsilon) return null;

  // Up is (0, -1) because y grows downward.
  final cosine = (-dy / mag).clamp(-1.0, 1.0);
  return math.acos(cosine) * _radToDeg;
}

/// The point halfway between [a] and [b].
Point2 midpoint(Point2 a, Point2 b) =>
    Point2((a.x + b.x) / 2, (a.y + b.y) / 2);

/// Euclidean distance between [a] and [b] in normalized units.
double distance(Point2 a, Point2 b) {
  final double dx = a.x - b.x, dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}
