import 'dart:async';

import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:pose_camera/pose_camera.dart';
import 'package:pose_core/pose_core.dart';

import '../../di/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../../services/coach_voice.dart';
import '../../theme/app_theme.dart';
import '../common/async_view.dart';
import '../common/ui_keys.dart';
import 'skeleton_overlay.dart';

/// The coach: set up the phone, run a set, and log what it saw.
///
/// Grew out of M4's camera check, which is still the first thing it does —
/// knowing where to put the phone is a prerequisite for everything else,
/// and getting it wrong is the most likely reason the coach would appear
/// not to work at all. From M7 it also runs the set: it counts, it judges,
/// it talks, and it offers to write what it watched into the log.
///
/// It can be opened without a set to run, which is the camera check it used
/// to be. [planned] and [setIndex] are what turn it into a set runner.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({
    required this.exerciseId,
    this.planned,
    this.setIndex,
    super.key,
  });

  final String exerciseId;

  /// The prescription this set is being performed against, when there is
  /// one. Without it the screen is a camera check and logs nothing.
  final PlannedExercise? planned;

  /// Which set of that prescription this is, from zero.
  final int? setIndex;

  /// Whether this screen can write what it watched into the log.
  bool get canLog => planned != null && setIndex != null;

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
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
        planned: widget.planned,
        setIndex: widget.setIndex,
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

/// Where the set is.
enum _Phase {
  /// Camera running, counter not. Nothing is counted until the user says
  /// so: a set that started itself would hand a rep to anybody who walked
  /// past the phone.
  ready,
  running,

  /// Stopped, with something to show and — when there is a session to put
  /// it in — something to save.
  finished,
}

/// The running camera: where to stand, what it can see, what it counted,
/// what it made of it, and what it does not promise.
///
/// Stateful because a set is: it starts when the user says so, it ends when
/// they say so, and what the camera saw in between is the thing being
/// offered to the log. The analyzer itself lives in a provider — the screen
/// owns when a set runs, not what counts as a rep.
class _Live extends ConsumerStatefulWidget {
  const _Live({
    required this.info,
    required this.camera,
    required this.exerciseId,
    required this.planned,
    required this.setIndex,
  });

  final PoseSourceInfo info;
  final CameraSupport camera;
  final String exerciseId;
  final PlannedExercise? planned;
  final int? setIndex;

  bool get canLog => planned != null && setIndex != null;

  @override
  ConsumerState<_Live> createState() => _LiveState();
}

class _LiveState extends ConsumerState<_Live> {
  _Phase _phase = _Phase.ready;

  /// Which attempt at this set is being watched. Part of the analyzer's
  /// key, so that starting again is a new analyzer rather than an old one
  /// asked nicely.
  int _run = 0;

  /// The last thing the analyzer said, kept so that stopping the set has
  /// something to show and to save.
  CoachTick? _tick;

  CoachVoice? _voice;
  bool _muted = false;
  bool _saved = false;
  String? _saveError;

  bool get _isHold =>
      widget.planned?.metric == MetricType.holdSeconds ||
      ref.read(catalogProvider).require(widget.exerciseId).metric ==
          MetricType.holdSeconds;

  /// The prescription this set is being judged against, for the one cue
  /// that is about progress rather than about position.
  ///
  /// The bottom of the rep range rather than the top: that is the number
  /// the set was committed to, and anything above it is a bonus nobody
  /// needs to be told about.
  CoachRequest get _request => CoachRequest(
        exerciseId: widget.exerciseId,
        run: _run,
        targetReps: _isHold ? null : widget.planned?.repsMin,
        targetHold: _isHold && widget.planned?.holdSeconds != null
            ? Duration(seconds: widget.planned!.holdSeconds!)
            : null,
      );

  @override
  void dispose() {
    unawaited(_voice?.dispose());
    super.dispose();
  }

  /// Built late and once, because it needs the user's coach style and the
  /// localizations, and neither is available in [initState].
  CoachVoice _voiceFor(BuildContext context) {
    final profile = ref.read(profileProvider).value;
    return _voice ??= CoachVoice(
      speaker: ref.read(coachSpeakerProvider),
      strings: PlanStrings.of(context, ref.read(catalogProvider)),
      style: profile?.coachStyle ?? CoachStyle.fallback,
    )..enabled = !_muted;
  }

  void _start() {
    // A fresh analyzer, so the next set starts from zero however the last
    // one ended. The old one is dropped rather than reset: a refreshed
    // stream keeps its previous value until the next frame arrives, and
    // for that moment the new set would be showing the old set's count.
    ref.invalidate(coachTickProvider(_request));
    setState(() {
      _run++;
      _phase = _Phase.running;
      _tick = null;
      _saved = false;
      _saveError = null;
    });
  }

  Future<void> _stop() async {
    await _voice?.stop();
    setState(() => _phase = _Phase.finished);
  }

  /// Logs that something hurt, ends the set, and says so.
  ///
  /// The same sentence as the session screen's pain button, deliberately:
  /// there is one thing this product says about pain and it is that you do
  /// not train through it.
  Future<void> _pain() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sessionPainTitle),
        content: Text(l10n.sessionPainBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.planCancel),
          ),
          FilledButton(
            key: UiKeys.coachPainConfirm,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.sessionPainConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _stop();
    await ref.read(sessionControllerProvider).reportPain();
    if (mounted) await _save();
  }

  Future<void> _save() async {
    final review = _tick?.review;
    if (!widget.canLog || review == null) return;

    final counter = _tick?.counter;
    final held = counter is HoldTick ? counter.held : null;
    try {
      await ref.read(sessionControllerProvider).logSet(
            exerciseId: widget.exerciseId,
            setIndex: widget.setIndex!,
            reps: _isHold ? null : review.counted,
            holdSeconds: _isHold ? (held?.inSeconds ?? 0) : null,
            weightKg: widget.planned?.targetWeightKg,
            review: review,
            // The angle the screen asked for, not one it detected: nothing
            // here can tell where the phone actually ended up.
            cameraAngle: widget.camera.recommendedAngle,
          );
      if (mounted) setState(() => _saved = true);
    } on Object {
      if (mounted) {
        setState(() => _saveError = AppLocalizations.of(context).coachSaveFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));

    final frames = ref.watch(poseFrameProvider);
    final frame = frames.value;
    final failure = frames.error;
    final verdict = frame == null ? null : Framing.assess(frame);
    final severity = verdict?.severity ?? FramingSeverity.blocked;

    if (_phase == _Phase.running) {
      // Keeping the newest tick, and feeding the voice, without doing
      // either from inside a build. A widget that spoke from `build` would
      // say everything again every time the framing bar changed colour.
      ref.listen(coachTickProvider(_request), (previous, next) {
        final tick = next.value;
        if (tick == null) return;
        _tick = tick;
        _voiceFor(context).onTick(tick);
      });
    }

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _heading(l10n),
                      key: UiKeys.coachHeading,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    key: UiKeys.coachMute,
                    tooltip: _muted ? l10n.coachUnmute : l10n.coachMute,
                    icon: Icon(
                      _muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                    ),
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      _voice?.enabled = !_muted;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${strings.cameraAngle(widget.camera.recommendedAngle)} '
                '${l10n.coachDistance}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _Preview(info: widget.info, frame: frame, severity: severity),
        ),
        _FramingBar(
          key: UiKeys.coachFraming,
          message: message,
          severity: failure == null ? severity : FramingSeverity.blocked,
        ),
        if (_phase == _Phase.running) _Coach(request: _request),
        if (_phase == _Phase.finished)
          _Summary(
            tick: _tick,
            isHold: _isHold,
            weightKg: widget.planned?.targetWeightKg,
            saved: _saved,
            error: _saveError,
            strings: strings,
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Text(
                  l10n.coachFormUntested,
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
                ..._actions(l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _heading(AppLocalizations l10n) {
    final planned = widget.planned;
    final index = widget.setIndex;
    if (planned == null || index == null) return l10n.coachSetupTitle;
    return l10n.coachSetOf(index + 1, planned.sets);
  }

  List<Widget> _actions(AppLocalizations l10n) => switch (_phase) {
        _Phase.ready => [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: UiKeys.coachStart,
                onPressed: _start,
                child: Text(l10n.coachStartSet),
              ),
            ),
            TextButton(
              key: UiKeys.coachDone,
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.coachDone),
            ),
          ],
        _Phase.running => [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: UiKeys.coachStop,
                onPressed: _stop,
                child: Text(l10n.coachStopSet),
              ),
            ),
            // On screen for the whole set, never behind a scroll: a pain
            // button somebody has to go looking for is a pain button that
            // gets used after the injury.
            if (widget.canLog)
              TextButton(
                key: UiKeys.coachPain,
                onPressed: _pain,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.sessionPainButton),
              ),
          ],
        _Phase.finished => [
            if (widget.canLog && !_saved)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: UiKeys.coachSave,
                  onPressed: (_tick?.review.counted ?? 0) > 0 || _isHold
                      ? _save
                      : null,
                  child: Text(l10n.coachSaveSet),
                ),
              ),
            // Running it again is the other thing somebody wants here: a
            // set that went wrong is repeated, not saved. Leaving is the
            // back arrow, which is always there.
            TextButton(
              key: UiKeys.coachStart,
              onPressed: _start,
              child: Text(
                widget.canLog && !_saved
                    ? l10n.coachDiscardSet
                    : l10n.coachStartSet,
              ),
            ),
            if (_saved)
              TextButton(
                key: UiKeys.coachDone,
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.coachDone),
              ),
          ],
      };
}

/// What the set came to, once it has stopped.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.tick,
    required this.isHold,
    required this.weightKg,
    required this.saved,
    required this.error,
    required this.strings,
  });

  final CoachTick? tick;
  final bool isHold;
  final double? weightKg;
  final bool saved;
  final String? error;
  final PlanStrings strings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final review = tick?.review;
    final counter = tick?.counter;
    final score = review?.formScore;
    final counted = review?.counted ?? 0;

    final parts = <String>[
      if (isHold)
        l10n.coachSummaryHold(
          counter is HoldTick ? counter.held.inSeconds : 0,
        )
      else
        l10n.coachSummaryReps(counted),
      if (weightKg != null) l10n.coachSummaryAt(strings.weight(weightKg!)),
      if (score != null)
        l10n.coachSummaryScore(score.round())
      else
        l10n.coachSummaryNoScore,
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parts.join(' · '),
            key: UiKeys.coachSummary,
            style: theme.textTheme.titleMedium,
          ),
          if (!isHold && counted == 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.coachNothingCounted,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (saved) ...[
            const SizedBox(height: 4),
            Text(
              l10n.coachSetSaved,
              key: UiKeys.coachSaved,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.extension<FormSeverityColors>()!.good,
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              key: UiKeys.coachSaveError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
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

/// What the coach has made of the set so far: the count, and the rules.
///
/// Reads the analyzer through a provider rather than owning one: it is
/// stateful, and a widget that fed frames to one from `build` would count
/// every rebuild as movement.
class _Coach extends ConsumerWidget {
  const _Coach({required this.request});

  final CoachRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(catalogProvider);
    final strings = PlanStrings.of(context, catalog);
    final tick = ref.watch(coachTickProvider(request));
    final value = tick.value;

    // An error with no value behind it is a coach that could not be built at
    // all. An error with a value is one frame the stream could not read,
    // which the framing bar above has already said out loud.
    if (value == null) {
      return _Panel(
        child: Text(
          tick.hasError ? l10n.coachCounterUnavailable : l10n.coachStarting,
          key: UiKeys.coachVerdict,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (value.counter) {
          final RepTick rep => _RepPanel(tick: rep, strings: strings),
          final HoldTick hold => _HoldPanel(tick: hold, strings: strings),
        },
        _FormPanel(
          tick: value,
          // The rules the exercise has at the angle the set is being
          // coached from, which is what decides the list of things the
          // panel admits it is not watching.
          selection: rulesFor(catalog.require(request.exerciseId)),
          strings: strings,
        ),
      ],
    );
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

/// What the form rules made of the set, and what they are not looking at.
///
/// Shows the last finished rep's verdict where there is one and the live
/// window otherwise, which is what makes a plank say something while it is
/// being held and a squat say something after each rep rather than during
/// it.
///
/// The second line is the part that is easy to leave out and should not be.
/// A coach that says nothing about a user's knees is making a claim, and the
/// three reasons it might be silent — the angle cannot see it, the engine
/// does not do it yet, the signal was lost — are not the same as approval.
class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.tick,
    required this.selection,
    required this.strings,
  });

  final CoachTick tick;
  final RuleSelection selection;
  final PlanStrings strings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<FormSeverityColors>()!;

    final verdict = tick.last ?? tick.live;
    final score = tick.review.formScore;
    final unchecked = strings.formUnchecked(selection);

    final color = switch (verdict.worst) {
      null => verdict.checked == 0
          ? theme.colorScheme.onSurfaceVariant
          : colors.good,
      RuleSeverity.minor => colors.minor,
      RuleSeverity.major => colors.major,
      RuleSeverity.unsafe => colors.unsafe,
    };

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verdict.unsafe
                    ? Icons.warning_amber_outlined
                    : Icons.visibility_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.formVerdict(verdict),
                  key: UiKeys.coachForm,
                  style: theme.textTheme.bodyMedium?.copyWith(color: color),
                ),
              ),
              if (score != null) ...[
                const SizedBox(width: 10),
                Text(
                  l10n.coachFormScore(score.round()),
                  key: UiKeys.coachFormScore,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (unchecked != null) ...[
            const SizedBox(height: 6),
            Text(
              unchecked,
              key: UiKeys.coachFormUnchecked,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
