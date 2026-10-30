import 'package:meta/meta.dart';

import 'point2.dart';

/// A single tracked body landmark for one frame.
@immutable
class Landmark {
  Landmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  }) : assert(
          visibility >= 0 && visibility <= 1,
          'visibility must be in 0..1, got $visibility',
        );

  /// Normalized horizontal position; grows to the right.
  final double x;

  /// Normalized vertical position; grows **downward**.
  final double y;

  /// Depth relative to the model's hip origin. Only loosely calibrated, so
  /// form rules should prefer 2D relationships wherever they can.
  final double z;

  /// Model confidence that this landmark is present and correctly placed.
  final double visibility;

  Point2 get point => Point2(x, y);

  @override
  bool operator ==(Object other) =>
      other is Landmark &&
      other.x == x &&
      other.y == y &&
      other.z == z &&
      other.visibility == visibility;

  @override
  int get hashCode => Object.hash(x, y, z, visibility);

  @override
  String toString() => 'Landmark(${x.toStringAsFixed(3)}, '
      '${y.toStringAsFixed(3)}, v=${visibility.toStringAsFixed(2)})';
}
