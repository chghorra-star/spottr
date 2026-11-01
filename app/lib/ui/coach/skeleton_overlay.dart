import 'package:flutter/material.dart';
import 'package:pose_core/pose_core.dart';

import '../../theme/app_theme.dart';

/// The tracked skeleton, drawn over the camera preview.
///
/// This is the only honest answer to "is it working". A framing verdict in
/// words can be right about a body it has mislocated; a skeleton that does
/// not follow the user is obvious at a glance.
///
/// It draws **only what is being tracked**. A bone with one end unseen is
/// absent rather than drawn to the last place that joint was, because a limb
/// resting where the tracker lost it looks exactly like a measurement.
class SkeletonOverlay extends StatelessWidget {
  const SkeletonOverlay({
    required this.frame,
    this.severity = FramingSeverity.good,
    super.key,
  });

  /// The latest frame, or null before one has arrived.
  final PoseFrame? frame;

  /// Colours the figure, so "I cannot use this" is visible without reading.
  final FramingSeverity severity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FormSeverityColors>()!;

    return CustomPaint(
      painter: SkeletonPainter(
        frame: frame,
        color: switch (severity) {
          FramingSeverity.good => colors.good,
          FramingSeverity.adjust => colors.minor,
          FramingSeverity.blocked => colors.unsafe,
        },
      ),
    );
  }
}

/// Strokes the bones and dots the joints of one frame.
///
/// Landmarks are in normalized image space and the painter's own size is
/// the image — see `PoseCameraPreview`, which letterboxes the preview
/// precisely so that this multiply is all the mapping there is.
class SkeletonPainter extends CustomPainter {
  const SkeletonPainter({required this.frame, required this.color});

  final PoseFrame? frame;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final current = frame;
    if (current == null) return;

    // Scaled to the box rather than fixed, so the figure reads the same on
    // a phone held at arm's length and in a screenshot on a desk.
    final stroke = size.shortestSide * 0.012;
    final bone = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final joint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Offset at(Point2 point) => Offset(point.x * size.width, point.y * size.height);

    for (final (from, to) in Skeleton.visibleBones(current)) {
      canvas.drawLine(at(from), at(to), bone);
    }

    // Once per joint, not once per bone that ends on it: a knee belongs to
    // two bones, and drawing its dot twice puts a visibly heavier mark on
    // every joint in the middle of a limb.
    for (final tracked in Skeleton.joints) {
      final point = current.point(tracked);
      if (point != null) canvas.drawCircle(at(point), stroke * 1.1, joint);
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.color != color;
}
