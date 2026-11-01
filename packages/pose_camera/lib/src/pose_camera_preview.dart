import 'package:flutter/material.dart';

import 'pose_source.dart';

/// The camera preview, with room for something drawn over it.
///
/// **The preview is letterboxed, not cropped, and that is a correctness
/// decision rather than a cosmetic one.** Landmarks arrive in normalized
/// image space, so an overlay can map them to pixels with a multiply — but
/// only while the box it is drawn in really is the image. Fill the screen
/// with `BoxFit.cover` and the box is a crop of the image, every landmark
/// needs the same crop applied, and the day somebody changes the fit the
/// skeleton silently slides off the body. Letterboxing keeps the two in
/// step by construction, and the user needs to see the whole frame anyway
/// to know whether they are in it.
///
/// [overlay] is stacked inside the same aspect-ratio box, so it can treat
/// its own size as the image.
class PoseCameraPreview extends StatelessWidget {
  const PoseCameraPreview({required this.info, this.overlay, super.key});

  final PoseSourceInfo info;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final texture = info.textureId;

    return Center(
      child: AspectRatio(
        aspectRatio: info.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (texture == null)
              // A source with no pixels: a replayed fixture under test, or
              // a device whose preview has not arrived yet. The landmarks
              // are the point, so the overlay still draws.
              ColoredBox(color: Theme.of(context).colorScheme.surfaceDim)
            else
              Texture(textureId: texture),
            ?overlay,
          ],
        ),
      ),
    );
  }
}
