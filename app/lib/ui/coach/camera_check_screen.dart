import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pose_camera/pose_camera.dart';
import 'package:pose_core/pose_core.dart';

import '../../di/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../../theme/app_theme.dart';
import '../common/async_view.dart';
import '../common/ui_keys.dart';
import 'skeleton_overlay.dart';

/// Setting the phone up so the coach can see the user.
///
/// M4's whole visible surface, and useful on its own: knowing where to put
/// the phone is a prerequisite for every later milestone, and getting it
/// wrong is the most likely reason the coach would appear not to work.
/// Rep counting lands in M5 and form rules in M6; this screen deliberately
/// claims nothing beyond "I can see you".
class CameraCheckScreen extends ConsumerStatefulWidget {
  const CameraCheckScreen({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  ConsumerState<CameraCheckScreen> createState() => _CameraCheckState();
}

class _CameraCheckState extends ConsumerState<CameraCheckScreen> {
  /// Read once, in [initState], and never through [ref] again.
  ///
  /// [dispose] has to stop the camera, and by then reading a provider
  /// through this widget throws — the lesson M3 learned the hard way on a
  /// phone, with every widget test passing.
  late final PoseSource _camera;
  late final AppLifecycleListener _lifecycle;

  CameraPermissionStatus? _permission;

  /// Null until the camera has been asked to start.
  AsyncValue<PoseSourceInfo>? _source;

  @override
  void initState() {
    super.initState();
    _camera = ref.read(poseSourceProvider);

    // Portrait only. A phone propped against a water bottle tips, and a
    // skeleton that reorients mid-set is both useless and alarming.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // A camera left running in the background is somebody's battery and
    // somebody's privacy, in that order of how quickly they notice.
    _lifecycle = AppLifecycleListener(onPause: _release, onResume: _begin);
    _begin();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _camera.stop();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _begin() async {
    final permission = await _camera.permissionStatus();
    if (!mounted) return;
    setState(() => _permission = permission);
    if (permission != CameraPermissionStatus.granted) return;
    await _start();
  }

  Future<void> _start() async {
    setState(() => _source = const AsyncValue<PoseSourceInfo>.loading());
    try {
      final info = await _camera.start();
      if (!mounted) return;
      setState(() => _source = AsyncValue<PoseSourceInfo>.data(info));
    } on PoseCameraException catch (error, stack) {
      if (!mounted) return;
      setState(
        () => _source = AsyncValue<PoseSourceInfo>.error(error, stack),
      );
    }
  }

  Future<void> _ask() async {
    final permission = await _camera.requestPermission();
    if (!mounted) return;
    setState(() => _permission = permission);
    if (permission == CameraPermissionStatus.granted) await _start();
  }

  void _release() {
    _camera.stop();
    if (mounted) setState(() => _source = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(catalogProvider);
    final camera = catalog.require(widget.exerciseId).camera;

    return Scaffold(
      key: UiKeys.coachScreen,
      appBar: AppBar(title: Text(l10n.coachTitle)),
      body: camera == null
          // Reachable only through a bug, but a blank screen would be a
          // worse way to find out about it.
          ? EmptyPanel(
              key: UiKeys.coachNotSupported,
              title: l10n.coachNotSupportedTitle,
              body: l10n.coachNotSupportedBody,
              actionLabel: l10n.coachDone,
              onAction: () => Navigator.of(context).maybePop(),
            )
          : _body(camera),
    );
  }

  Widget _body(CameraSupport camera) {
    final l10n = AppLocalizations.of(context);

    return switch (_permission) {
      null => const Center(
          child: CircularProgressIndicator(key: UiKeys.loading),
        ),
      CameraPermissionStatus.denied => _Permission(
          key: UiKeys.coachPermission,
          title: l10n.coachPermissionTitle,
          body: l10n.coachPermissionBody,
          actionLabel: l10n.coachPermissionAllow,
          onAction: _ask,
        ),
      // No button: the only thing that can grant it now is the system
      // settings, and a button that cannot work makes the app look broken.
      CameraPermissionStatus.permanentlyDenied => _Permission(
          key: UiKeys.coachBlocked,
          title: l10n.coachPermissionBlockedTitle,
          body: l10n.coachPermissionBlockedBody,
        ),
      CameraPermissionStatus.granted => _started(camera),
    };
  }

  Widget _started(CameraSupport camera) {
    final l10n = AppLocalizations.of(context);
    final source = _source;

    if (source == null) {
      return Center(child: Text(l10n.coachStarting, key: UiKeys.loading));
    }

    return source.when(
      loading: () => const Center(
        child: CircularProgressIndicator(key: UiKeys.loading),
      ),
      error: (error, _) => EmptyPanel(
        key: UiKeys.coachError,
        title: l10n.coachErrorTitle,
        body: error is PoseCameraException
            ? PlanStrings.of(context, ref.read(catalogProvider))
                .cameraError(error.error)
            : l10n.coachErrorUnknown,
        actionLabel: l10n.coachErrorRetry,
        onAction: _start,
      ),
      data: (info) => _Live(
        info: info,
        camera: camera,
        exerciseId: widget.exerciseId,
      ),
    );
  }
}

/// Why the camera is needed, and — when it can still be granted — the ask.
class _Permission extends StatelessWidget {
  const _Permission({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = actionLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (label != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                key: UiKeys.coachPermissionAllow,
                onPressed: onAction,
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The running camera: where to stand, what it can see, what it counted,
/// and what it does not promise.
class _Live extends ConsumerWidget {
  const _Live({
    required this.info,
    required this.camera,
    required this.exerciseId,
  });

  final PoseSourceInfo info;
  final CameraSupport camera;
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));

    final frames = ref.watch(poseFrameProvider);
    final frame = frames.value;
    final failure = frames.error;
    final verdict = frame == null ? null : Framing.assess(frame);
    final severity = verdict?.severity ?? FramingSeverity.blocked;

    // A failure part way through has to say so. Without this the model
    // failing to load looks exactly like an empty room: a preview that
    // works, and a bar that says it cannot see anybody, for ever.
    final message = switch ((failure, verdict)) {
      (final PoseCameraException error, _) => strings.cameraError(error.error),
      // Anything else that reached the stream. Shown raw, like the other
      // error panels: the one person who can report it needs something to
      // report.
      (final Object error, _) => '$error',
      (_, null) => l10n.coachFramingNoPerson,
      (_, final FramingVerdict value) => strings.framingAdvice(value),
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.coachSetupTitle, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                '${strings.cameraAngle(camera.recommendedAngle)} '
                '${l10n.coachDistance}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _Preview(info: info, frame: frame, severity: severity),
        ),
        _FramingBar(
          key: UiKeys.coachFraming,
          message: message,
          severity: failure == null ? severity : FramingSeverity.blocked,
        ),
        _Counter(exerciseId: exerciseId),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Text(
                  l10n.coachCountingOnly,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.coachClaim,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: UiKeys.coachDone,
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.coachDone),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The preview and the skeleton, flipped together or not at all.
///
/// The front lens is shown mirrored, the way a gym mirror is. Both the
/// picture and the figure drawn on it are flipped by this one transform, so
/// they cannot come apart — which is what would happen if the flip were
/// also applied to the landmarks on the way across the bridge.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.info,
    required this.frame,
    required this.severity,
  });

  final PoseSourceInfo info;
  final PoseFrame? frame;
  final FramingSeverity severity;

  @override
  Widget build(BuildContext context) {
    final preview = PoseCameraPreview(
      info: info,
      overlay: SkeletonOverlay(frame: frame, severity: severity),
    );

    if (!info.mirrored) return preview;
    return Transform.flip(flipX: true, child: preview);
  }
}

class _FramingBar extends StatelessWidget {
  const _FramingBar({
    required this.message,
    required this.severity,
    super.key,
  });

  final String message;
  final FramingSeverity severity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FormSeverityColors>()!;
    final color = switch (severity) {
      FramingSeverity.good => colors.good,
      FramingSeverity.adjust => colors.minor,
      FramingSeverity.blocked => colors.unsafe,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withValues(alpha: 0.16),
      child: Row(
        children: [
          Icon(
            severity == FramingSeverity.good
                ? Icons.check_circle_outline
                : Icons.center_focus_weak_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the counter has made of the set so far.
///
/// Reads the counter through a provider rather than owning one: a counter is
/// stateful, and a widget that fed frames to one from `build` would count
/// every rebuild as movement.
class _Counter extends ConsumerWidget {
  const _Counter({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));
    final tick = ref.watch(counterTickProvider(exerciseId));
    final value = tick.value;

    // An error with no value behind it is a counter that could not be built
    // at all. An error with a value is one frame the stream could not read,
    // which the framing bar above has already said out loud.
    if (value == null) {
      return _Panel(
        child: Text(
          tick.hasError ? l10n.coachCounterUnavailable : l10n.coachStarting,
          key: UiKeys.coachVerdict,
        ),
      );
    }

    return switch (value) {
      RepTick() => _RepPanel(tick: value, strings: strings),
      HoldTick() => _HoldPanel(tick: value, strings: strings),
    };
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: child,
      );
}

/// The rep count, and what became of the last attempt.
///
/// Reads `tick.last` rather than `tick.completed`. The camera produces
/// frames faster than this rebuilds, so the single frame an attempt landed
/// on may never reach a widget at all — which is why the counter carries
/// the standing value and the screen holds no state of its own.
class _RepPanel extends StatelessWidget {
  const _RepPanel({required this.tick, required this.strings});

  final RepTick tick;
  final PlanStrings strings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<FormSeverityColors>()!;
    final last = tick.last;
    final rejected = tick.attempts - tick.counted;

    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${tick.counted}',
            key: UiKeys.coachCount,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.coachRepsLabel(tick.counted),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (last != null)
                  Text(
                    strings.repVerdict(last),
                    key: UiKeys.coachVerdict,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: switch (last.outcome) {
                        RepOutcome.counted => colors.good,
                        RepOutcome.countedWithWarning => colors.minor,
                        RepOutcome.notCounted => colors.unsafe,
                      },
                    ),
                  ),
                // The ledger, in one line. A rep the user felt and the
                // counter refused has to be visible without being shouted
                // about: they can see the reason for the last one and the
                // tally for the rest.
                if (rejected > 0)
                  Text(
                    l10n.coachRepsNotCounted(rejected),
                    key: UiKeys.coachLedger,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Time held, and whether the clock is running.
class _HoldPanel extends StatelessWidget {
  const _HoldPanel({required this.tick, required this.strings});

  final HoldTick tick;
  final PlanStrings strings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<FormSeverityColors>()!;
    final seconds = tick.held.inSeconds;

    return _Panel(
      child: Row(
        children: [
          Text(
            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
            key: UiKeys.coachCount,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.coachHeldLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              strings.holdState(tick),
              key: UiKeys.coachVerdict,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tick.accumulating ? colors.good : colors.minor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
