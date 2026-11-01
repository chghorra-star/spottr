import 'dart:math' as math;

import 'package:pose_core/pose_core.dart';
import 'package:test/test.dart';

Duration _ms(int value) => Duration(milliseconds: value);

/// Spread of a sequence, as a stand-in for how much it wobbles.
double _spread(List<double> values) {
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance = values
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b) /
      values.length;
  return math.sqrt(variance);
}

PoseFrame _frame(
  int id,
  Duration t,
  Map<Joint, Landmark> landmarks, {
  double confidence = 0.9,
}) =>
    PoseFrame(
      frameId: id,
      t: t,
      landmarks: landmarks,
      confidence: confidence,
    );

Landmark _lm(double x, double y, {double visibility = 1}) =>
    Landmark(x: x, y: y, z: 0, visibility: visibility);

void main() {
  group('OneEuroFilter', () {
    test('passes the first sample through untouched', () {
      final filter = OneEuroFilter();
      expect(filter.filter(0.42, Duration.zero), 0.42);
    });

    test('leaves a constant signal alone', () {
      final filter = OneEuroFilter();
      for (var i = 0; i < 30; i++) {
        expect(filter.filter(0.5, _ms(i * 33)), closeTo(0.5, 1e-9));
      }
    });

    test('damps a step instead of following it', () {
      final filter = OneEuroFilter()..filter(0.0, Duration.zero);
      final first = filter.filter(1.0, _ms(33));

      expect(first, greaterThan(0.0));
      expect(first, lessThan(1.0));
    });

    test('converges on a held value', () {
      final filter = OneEuroFilter()..filter(0.0, Duration.zero);
      var value = 0.0;
      for (var i = 1; i <= 40; i++) {
        value = filter.filter(1.0, _ms(i * 33));
      }
      expect(value, closeTo(1.0, 0.02));
    });

    test('attenuates jitter around a fixed position', () {
      final random = math.Random(7);
      final filter = OneEuroFilter();
      final input = <double>[];
      final output = <double>[];

      for (var i = 0; i < 90; i++) {
        final noisy = 0.5 + (random.nextDouble() - 0.5) * 0.04;
        input.add(noisy);
        output.add(filter.filter(noisy, _ms(i * 33)));
      }

      expect(_spread(output), lessThan(_spread(input) / 2));
    });

    test('lags less on fast movement than a fixed cutoff would', () {
      // This is the whole point of the one-euro filter over a plain
      // low-pass: the cutoff rises with speed, so a squat descent is
      // tracked while a stationary ankle stops shimmering. With beta at
      // zero it degenerates to a fixed low-pass and falls behind.
      double rampEnd({required double beta}) {
        final filter = OneEuroFilter(beta: beta);
        var value = 0.0;
        for (var i = 0; i <= 10; i++) {
          value = filter.filter(i * 0.05, _ms(i * 33));
        }
        return value;
      }

      final adaptive = rampEnd(beta: 0.05);
      final fixed = rampEnd(beta: 0);
      expect(adaptive, greaterThan(fixed));
      expect(adaptive, lessThanOrEqualTo(0.5));
    });

    test('survives two samples with the same timestamp', () {
      // ML Kit can hand over two frames stamped the same millisecond. A
      // naive derivative divides by zero and poisons the filter with
      // infinity from then on.
      final filter = OneEuroFilter()..filter(0.2, _ms(100));
      final value = filter.filter(0.3, _ms(100));

      expect(value.isFinite, isTrue);
      expect(filter.filter(0.3, _ms(133)).isFinite, isTrue);
    });

    test('forgets its history on reset', () {
      final filter = OneEuroFilter()..filter(0.0, Duration.zero);
      filter.filter(0.0, _ms(33));
      filter.reset();

      expect(filter.filter(1.0, _ms(66)), 1.0);
    });

    test('keeps up with a fast movement as well as a slow one', () {
      // The whole reason this filter is adaptive rather than a plain
      // low-pass. A fixed cutoff lags in proportion to speed, so a squat
      // descent would read several degrees shallower than it was and a fast
      // rep much shallower than that — the harness is what found it, with
      // `beta` three orders of magnitude too small for a signal measured in
      // normalized image units rather than in pixels.
      double lag(Duration step) {
        final filter = OneEuroFilter();
        var t = Duration.zero;
        var value = 0.0;
        var filtered = 0.0;
        // The same 0.3 units of travel either way, timed differently.
        for (var i = 1; i <= 10; i++) {
          value = i * 0.03;
          t += step;
          filtered = filter.filter(value, t);
        }
        return value - filtered;
      }

      final slow = lag(_ms(100));
      final fast = lag(_ms(25));

      expect(slow, greaterThan(0));
      expect(fast, lessThan(slow * 2));
    });

    test('still smooths a signal that is barely moving', () {
      // The other half of the trade: the cutoff may rise with speed, but
      // landmark noise on a planted ankle must not count as speed.
      final filter = OneEuroFilter();
      final input = <double>[];
      final output = <double>[];
      var seed = 1;
      for (var i = 0; i < 40; i++) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final value = 0.5 + ((seed % 1000) / 1000 - 0.5) * 0.008;
        input.add(value);
        output.add(filter.filter(value, _ms(i * 33)));
      }

      expect(_spread(output), lessThan(_spread(input) / 2));
    });
  });

  group('PoseSmoother', () {
    test('passes the first frame through unchanged', () {
      final smoother = PoseSmoother();
      final frame = _frame(1, Duration.zero, {Joint.leftKnee: _lm(0.4, 0.6)});
      final smoothed = smoother.apply(frame);

      expect(smoothed.landmarks[Joint.leftKnee]!.x, closeTo(0.4, 1e-9));
      expect(smoothed.landmarks[Joint.leftKnee]!.y, closeTo(0.6, 1e-9));
    });

    test('keeps the frame id, timestamp and confidence', () {
      final smoother = PoseSmoother();
      final smoothed = smoother.apply(
        _frame(9, _ms(300), {Joint.leftKnee: _lm(0.4, 0.6)}, confidence: 0.77),
      );

      expect(smoothed.frameId, 9);
      expect(smoothed.t, _ms(300));
      expect(smoothed.confidence, 0.77);
    });

    test('attenuates jitter on a joint held still', () {
      final random = math.Random(11);
      final smoother = PoseSmoother();
      final input = <double>[];
      final output = <double>[];

      for (var i = 0; i < 90; i++) {
        final noisy = 0.5 + (random.nextDouble() - 0.5) * 0.04;
        input.add(noisy);
        output.add(
          smoother
              .apply(_frame(i, _ms(i * 33), {Joint.leftKnee: _lm(noisy, 0.6)}))
              .landmarks[Joint.leftKnee]!
              .x,
        );
      }

      expect(_spread(output), lessThan(_spread(input) / 2));
    });

    test('smooths each joint independently', () {
      final smoother = PoseSmoother();
      for (var i = 0; i < 20; i++) {
        smoother.apply(
          _frame(i, _ms(i * 33), {
            Joint.leftKnee: _lm(0.2, 0.6),
            Joint.rightKnee: _lm(0.8, 0.6),
          }),
        );
      }
      final smoothed = smoother.apply(
        _frame(20, _ms(660), {
          Joint.leftKnee: _lm(0.2, 0.6),
          Joint.rightKnee: _lm(0.8, 0.6),
        }),
      );

      expect(smoothed.landmarks[Joint.leftKnee]!.x, closeTo(0.2, 1e-3));
      expect(smoothed.landmarks[Joint.rightKnee]!.x, closeTo(0.8, 1e-3));
    });

    test('drops a joint the model stopped reporting rather than holding it', () {
      // Holding the last position would invent data, and the overlay would
      // draw a limb that is no longer being tracked.
      final smoother = PoseSmoother();
      smoother.apply(_frame(1, Duration.zero, {Joint.leftKnee: _lm(0.4, 0.6)}));
      final smoothed = smoother.apply(_frame(2, _ms(33), const {}));

      expect(smoothed.landmarks, isEmpty);
    });

    test('does not smooth a returning joint towards where it used to be', () {
      // A joint that went out of view and came back somewhere else is a new
      // observation, not a continuation. Smoothing across the gap drags the
      // skeleton in from the old position over the next half second.
      final smoother = PoseSmoother();
      smoother.apply(_frame(1, Duration.zero, {Joint.leftKnee: _lm(0.1, 0.6)}));
      smoother.apply(_frame(2, _ms(33), const {}));
      final back = smoother.apply(
        _frame(3, _ms(66), {Joint.leftKnee: _lm(0.9, 0.6)}),
      );

      expect(back.landmarks[Joint.leftKnee]!.x, closeTo(0.9, 1e-9));
    });

    test('starts over after a gap too long to be a dropped frame', () {
      final smoother = PoseSmoother(resetAfter: _ms(400));
      smoother.apply(_frame(1, Duration.zero, {Joint.leftKnee: _lm(0.1, 0.6)}));
      final later = smoother.apply(
        _frame(2, _ms(2000), {Joint.leftKnee: _lm(0.9, 0.6)}),
      );

      expect(later.landmarks[Joint.leftKnee]!.x, closeTo(0.9, 1e-9));
    });

    test('smooths across an ordinary dropped frame', () {
      final smoother = PoseSmoother(resetAfter: _ms(400));
      smoother.apply(_frame(1, Duration.zero, {Joint.leftKnee: _lm(0.1, 0.6)}));
      final next = smoother.apply(
        _frame(3, _ms(66), {Joint.leftKnee: _lm(0.9, 0.6)}),
      );

      expect(next.landmarks[Joint.leftKnee]!.x, lessThan(0.9));
    });

    test('steadies a flickering visibility', () {
      // Visibility is smoothed on a fixed alpha rather than the adaptive
      // filter: its wobble is not speed-related, and an overlay that blinks
      // a limb in and out looks broken even when the position is fine.
      final smoother = PoseSmoother();
      var visibility = 0.0;
      for (var i = 0; i < 10; i++) {
        visibility = smoother
            .apply(
              _frame(i, _ms(i * 33), {
                Joint.leftKnee: _lm(0.4, 0.6, visibility: i.isEven ? 1.0 : 0.0),
              }),
            )
            .landmarks[Joint.leftKnee]!
            .visibility;
      }

      expect(visibility, greaterThan(0.2));
      expect(visibility, lessThan(0.8));
    });

    test('keeps smoothed visibility inside 0..1', () {
      final smoother = PoseSmoother();
      for (var i = 0; i < 20; i++) {
        final visibility = smoother
            .apply(
              _frame(i, _ms(i * 33), {
                Joint.leftKnee: _lm(0.4, 0.6, visibility: 1),
              }),
            )
            .landmarks[Joint.leftKnee]!
            .visibility;
        expect(visibility, inInclusiveRange(0, 1));
      }
    });
  });

  group('PoseSmoothing as a stream transformer', () {
    test('smooths a stream of frames', () async {
      final frames = Stream.fromIterable([
        for (var i = 0; i < 3; i++)
          _frame(i, _ms(i * 33), {Joint.leftKnee: _lm(i == 0 ? 0.0 : 1.0, 0.5)}),
      ]);

      final smoothed =
          await frames.transform(const PoseSmoothing()).toList();

      expect(smoothed, hasLength(3));
      expect(smoothed.last.landmarks[Joint.leftKnee]!.x, lessThan(1.0));
    });

    test('gives every subscription its own filter state', () async {
      // The transformer is const and shared. If the filters lived on it
      // rather than per subscription, a second set would start smoothed
      // towards the end of the first.
      const transformer = PoseSmoothing();
      Stream<PoseFrame> source() => Stream.fromIterable([
            _frame(0, Duration.zero, {Joint.leftKnee: _lm(0.9, 0.5)}),
          ]);

      final first = await source().transform(transformer).first;
      final second = await source().transform(transformer).first;

      expect(first.landmarks[Joint.leftKnee]!.x, closeTo(0.9, 1e-9));
      expect(second.landmarks[Joint.leftKnee]!.x, closeTo(0.9, 1e-9));
    });
  });
}
