import 'package:meta/meta.dart';

/// A point in normalized image space.
///
/// `x` grows to the right and `y` grows **downward**, matching the image
/// convention used by both ML Kit and MediaPipe. Values are normally in
/// `0..1`, but a limb tracked just outside the frame can fall slightly
/// outside that range, so no clamping is applied.
@immutable
class Point2 {
  const Point2(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is Point2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point2(${x.toStringAsFixed(4)}, '
      '${y.toStringAsFixed(4)})';
}
