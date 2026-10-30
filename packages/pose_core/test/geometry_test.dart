import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

/// Landmarks are in normalized image space: x grows right, y grows DOWN.
/// These tests pin that convention down, because every form rule depends on it.
void main() {
  group('angleAtVertex', () {
    test('returns 180 degrees for a straight limb', () {
      final angle = angleAtVertex(
        const Point2(0.5, 0.2),
        const Point2(0.5, 0.5),
        const Point2(0.5, 0.8),
      );
      expect(angle, isNotNull);
      expect(angle!, closeTo(180, 0.001));
    });

    test('returns 90 degrees for a right angle', () {
      final angle = angleAtVertex(
        const Point2(0.5, 0.2),
        const Point2(0.5, 0.5),
        const Point2(0.8, 0.5),
      );
      expect(angle!, closeTo(90, 0.001));
    });

    test('returns 0 degrees for a fully folded limb', () {
      final angle = angleAtVertex(
        const Point2(0.5, 0.2),
        const Point2(0.5, 0.5),
        const Point2(0.5, 0.2),
      );
      expect(angle!, closeTo(0, 0.001));
    });

    test('is symmetric in its outer arguments', () {
      const a = Point2(0.31, 0.22);
      const b = Point2(0.48, 0.55);
      const c = Point2(0.77, 0.41);
      expect(angleAtVertex(a, b, c)!, closeTo(angleAtVertex(c, b, a)!, 1e-9));
    });

    test('is scale invariant', () {
      final small = angleAtVertex(
        const Point2(0.50, 0.40),
        const Point2(0.50, 0.50),
        const Point2(0.60, 0.50),
      );
      final large = angleAtVertex(
        const Point2(0.50, 0.00),
        const Point2(0.50, 0.50),
        const Point2(1.00, 0.50),
      );
      expect(small!, closeTo(large!, 1e-9));
    });

    test('returns null when a segment has zero length', () {
      // A degenerate frame must not poison downstream math with NaN.
      expect(
        angleAtVertex(
          const Point2(0.5, 0.5),
          const Point2(0.5, 0.5),
          const Point2(0.5, 0.8),
        ),
        isNull,
      );
    });

    test('never exceeds the acos domain for near-collinear input', () {
      // Floating point drift used to push the dot product past 1.0 here.
      final angle = angleAtVertex(
        const Point2(0.1, 0.1000000001),
        const Point2(0.2, 0.2),
        const Point2(0.3, 0.3),
      );
      expect(angle, isNotNull);
      expect(angle!.isNaN, isFalse);
      expect(angle, closeTo(180, 0.01));
    });
  });

  group('angleFromVertical', () {
    test('is 0 for a segment pointing straight up the image', () {
      final angle = angleFromVertical(
        const Point2(0.5, 0.8),
        const Point2(0.5, 0.2),
      );
      expect(angle!, closeTo(0, 0.001));
    });

    test('is 90 for a horizontal segment', () {
      final angle = angleFromVertical(
        const Point2(0.5, 0.5),
        const Point2(0.9, 0.5),
      );
      expect(angle!, closeTo(90, 0.001));
    });

    test('is unsigned, so lean direction does not matter', () {
      final left = angleFromVertical(
        const Point2(0.5, 0.8),
        const Point2(0.3, 0.4),
      );
      final right = angleFromVertical(
        const Point2(0.5, 0.8),
        const Point2(0.7, 0.4),
      );
      expect(left!, closeTo(right!, 1e-9));
    });

    test('is 180 for a segment pointing straight down the image', () {
      final angle = angleFromVertical(
        const Point2(0.5, 0.2),
        const Point2(0.5, 0.8),
      );
      expect(angle!, closeTo(180, 0.001));
    });
  });

  group('helpers', () {
    test('midpoint averages both axes', () {
      final m = midpoint(const Point2(0.2, 0.4), const Point2(0.6, 0.8));
      expect(m.x, closeTo(0.4, 1e-9));
      expect(m.y, closeTo(0.6, 1e-9));
    });

    test('distance is euclidean', () {
      final d = distance(const Point2(0, 0), const Point2(0.3, 0.4));
      expect(d, closeTo(0.5, 1e-9));
    });
  });

  group('realistic joint angles', () {
    test('a standing knee is near full extension', () {
      // hip above knee above ankle, roughly stacked
      final knee = angleAtVertex(
        const Point2(0.50, 0.40), // hip
        const Point2(0.50, 0.65), // knee
        const Point2(0.51, 0.90), // ankle
      );
      expect(knee!, greaterThan(170));
    });

    test('a deep squat knee is well under parallel', () {
      final knee = angleAtVertex(
        const Point2(0.44, 0.72), // hip, dropped to knee height and back
        const Point2(0.58, 0.72), // knee, driven forward over the foot
        const Point2(0.50, 0.90), // ankle
      );
      expect(knee!, inInclusiveRange(50, 100));
    });
  });
}
