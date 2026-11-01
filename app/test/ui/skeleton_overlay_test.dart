
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pose_core/pose_core.dart';
import 'package:spottr/theme/app_theme.dart';
import 'package:spottr/ui/coach/skeleton_overlay.dart';

PoseFrame _frame({int id = 1, double visibility = 1}) => PoseFrame(
      frameId: id,
      t: Duration(milliseconds: id * 33),
      landmarks: {
        Joint.leftHip: Landmark(x: 0.45, y: 0.5, z: 0, visibility: visibility),
        Joint.leftKnee: Landmark(x: 0.45, y: 0.7, z: 0, visibility: visibility),
        Joint.leftAnkle: Landmark(x: 0.45, y: 0.9, z: 0, visibility: visibility),
      },
      confidence: 0.9,
    );

Future<SkeletonPainter> _painterOf(
  WidgetTester tester,
  SkeletonOverlay overlay,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SizedBox(width: 300, height: 400, child: overlay)),
    ),
  );
  return tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!
      as SkeletonPainter;
}

/// Records what actually reached the canvas.
///
/// Image goldens would be the other way to check this, and they would pin
/// anti-aliasing and font rendering across platforms along with the thing
/// being tested. Counting the draw calls says exactly what the painter did.
class _CountingCanvas implements Canvas {
  final List<(Offset, Offset)> lines = [];
  final List<Offset> circles = [];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => lines.add((p1, p2));

  @override
  void drawCircle(Offset c, double radius, Paint paint) => circles.add(c);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

_CountingCanvas _draw(SkeletonPainter painter, [Size size = const Size(300, 400)]) {
  final canvas = _CountingCanvas();
  painter.paint(canvas, size);
  return canvas;
}

void main() {
  testWidgets('hands the frame to the painter', (tester) async {
    final frame = _frame();
    final painter = await _painterOf(tester, SkeletonOverlay(frame: frame));

    expect(painter.frame, same(frame));
  });

  testWidgets('takes its colour from the theme severity scale',
      (tester) async {
    // Not a colour chosen in the widget: the same scale appears in the rep
    // ledger and the set summary, and "major" being amber in one place and
    // red in another is how that goes wrong.
    const colors = FormSeverityColors(
      good: Color(0xFF35D07F),
      minor: Color(0xFFFFD166),
      major: Color(0xFFFFB020),
      unsafe: Color(0xFFFF4D4F),
    );

    final good = await _painterOf(
      tester,
      SkeletonOverlay(frame: _frame(), severity: FramingSeverity.good),
    );
    expect(good.color, colors.good);

    final adjust = await _painterOf(
      tester,
      SkeletonOverlay(frame: _frame(), severity: FramingSeverity.adjust),
    );
    expect(adjust.color, colors.minor);

    final blocked = await _painterOf(
      tester,
      SkeletonOverlay(frame: _frame(), severity: FramingSeverity.blocked),
    );
    expect(blocked.color, colors.unsafe);
  });

  testWidgets('repaints when a new frame arrives', (tester) async {
    // Thirty times a second, so this is the one that matters: a painter
    // that decided nothing had changed would freeze the skeleton.
    final first = SkeletonPainter(frame: _frame(), color: const Color(0xFF00FF00));
    final second = SkeletonPainter(
      frame: _frame(id: 2),
      color: const Color(0xFF00FF00),
    );

    expect(second.shouldRepaint(first), isTrue);
    expect(first.shouldRepaint(first), isFalse);
  });

  testWidgets('repaints when the framing verdict changes colour',
      (tester) async {
    final frame = _frame();
    final green = SkeletonPainter(frame: frame, color: const Color(0xFF00FF00));
    final red = SkeletonPainter(frame: frame, color: const Color(0xFFFF0000));

    expect(red.shouldRepaint(green), isTrue);
  });

  testWidgets('draws nothing at all before a frame arrives', (tester) async {
    final painter = await _painterOf(tester, const SkeletonOverlay(frame: null));
    final canvas = _draw(painter);

    expect(painter.frame, isNull);
    expect(canvas.lines, isEmpty);
    expect(canvas.circles, isEmpty);
  });

  testWidgets('draws nothing for joints it is not tracking', (tester) async {
    // A limb drawn where the tracker lost it looks exactly like a
    // measurement, which is worse than a gap.
    final painter = await _painterOf(
      tester,
      SkeletonOverlay(frame: _frame(visibility: 0.1)),
    );
    final canvas = _draw(painter);

    expect(canvas.lines, isEmpty);
    expect(canvas.circles, isEmpty);
  });

  testWidgets('draws one bone per tracked pair and one dot per joint',
      (tester) async {
    // The frame holds a hip, a knee and an ankle down one leg: two bones,
    // three dots. A dot per bone end would put two on the knee, which
    // reads as a heavier mark on every joint in the middle of a limb.
    final painter = await _painterOf(tester, SkeletonOverlay(frame: _frame()));
    final canvas = _draw(painter);

    expect(canvas.lines, hasLength(2));
    expect(canvas.circles, hasLength(3));
  });

  testWidgets('maps normalized landmarks onto its own box', (tester) async {
    // The preview is letterboxed precisely so this multiply is all the
    // mapping there is. A landmark at 0.45, 0.5 lands at 135, 200 in a
    // 300 by 400 box or the skeleton is not on the body.
    final painter = await _painterOf(tester, SkeletonOverlay(frame: _frame()));
    final canvas = _draw(painter);

    expect(canvas.circles, contains(const Offset(135, 200)));
    expect(canvas.circles, contains(const Offset(135, 280)));
  });
}
