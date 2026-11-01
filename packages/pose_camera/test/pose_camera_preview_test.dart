import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pose_camera/pose_camera.dart';

const _withTexture = PoseSourceInfo(
  imageWidth: 480,
  imageHeight: 640,
  lens: CameraLens.back,
  mirrored: false,
  textureId: 7,
);

const _withoutTexture = PoseSourceInfo(
  imageWidth: 480,
  imageHeight: 640,
  lens: CameraLens.back,
  mirrored: false,
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('renders the native texture the source reported', (tester) async {
    await _pump(tester, const PoseCameraPreview(info: _withTexture));

    expect(tester.widget<Texture>(find.byType(Texture)).textureId, 7);
  });

  testWidgets('shows a placeholder for a source with no pixels',
      (tester) async {
    // A replayed fixture has landmarks and nothing to look at. The overlay
    // is still the point, so the preview must not insist on a texture.
    await _pump(tester, const PoseCameraPreview(info: _withoutTexture));

    expect(find.byType(Texture), findsNothing);
    expect(find.byType(ColoredBox), findsWidgets);
  });

  testWidgets('lays the preview out at the source aspect ratio',
      (tester) async {
    await _pump(tester, const PoseCameraPreview(info: _withTexture));

    final box = tester.getSize(find.byType(AspectRatio));
    expect(box.width / box.height, closeTo(0.75, 1e-6));
  });

  testWidgets('gives the overlay exactly the preview box', (tester) async {
    // The overlay maps normalized landmarks straight onto its own size, so
    // the two have to be the same rectangle. If they ever drift apart the
    // skeleton slides off the body.
    await _pump(
      tester,
      const PoseCameraPreview(
        info: _withTexture,
        overlay: SizedBox.expand(child: Placeholder()),
      ),
    );

    expect(
      tester.getRect(find.byType(Placeholder)),
      tester.getRect(find.byType(AspectRatio)),
    );
  });
}
