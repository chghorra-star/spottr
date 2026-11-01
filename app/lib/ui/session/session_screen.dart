import 'package:collection/collection.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_engine/plan_engine.dart';

import '../../di/providers.dart';
import '../../domain/workout_session.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../coach/coach_screen.dart';
import '../common/async_view.dart';
import '../common/ui_keys.dart';
import 'finish_flow.dart';

/// Logging a workout, one set at a time.
///
/// The prescription is on screen next to the fields rather than behind a tap,
/// because the question the user is answering is "did I do what it said" and
/// they should not have to remember what it said.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({required this.weekday, super.key});

  final int weekday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: AsyncView<WeekPlan?>(
        value: plan,
        onRetry: () => ref.invalidate(activePlanProvider),
        builder: (context, data) {
          final day =
              data?.days.firstWhereOrNull((day) => day.weekday == weekday);
          if (day == null) {
            return EmptyPanel(
              key: UiKeys.sessionEmpty,
              title: l10n.sessionEmptyTitle,
              body: l10n.sessionEmptyBody,
              actionLabel: l10n.sessionSummaryDone,
              onAction: () => Navigator.of(context).maybePop(),
            );
          }
          return _SessionBody(day: day);
        },
      ),
    );
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.day});

  final PlannedDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    final l10n = AppLocalizations.of(context);

    return AsyncView<WorkoutSession?>(
      value: session,
      onRetry: () => ref.invalidate(activeSessionProvider),
      builder: (context, data) => data == null
          // Finishing and discarding both pop this route themselves. Landing
          // here means the session ended somewhere else — a second device,
          // eventually — so the screen says so rather than going blank.
          ? EmptyPanel(
              key: UiKeys.sessionOver,
              title: l10n.sessionEmptyTitle,
              body: l10n.sessionSummaryEmpty,
              actionLabel: l10n.sessionSummaryDone,
              onAction: () => Navigator.of(context).maybePop(),
            )
          : _LiveSession(day: day, session: data),
    );
  }
}

class _LiveSession extends ConsumerWidget {
  const _LiveSession({required this.day, required this.session});

  final PlannedDay day;
  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            key: UiKeys.sessionScreen,
            slivers: [
              SliverAppBar(
                title: Text(strings.day(day.labelKey)),
                actions: [
                  IconButton(
                    key: UiKeys.sessionDiscard,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.sessionDiscard,
                    onPressed: () => _discard(context, ref),
                  ),
                ],
              ),
              if (session.painReported)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _PainBanner(key: UiKeys.sessionPainBadge),
                  ),
                ),
              SliverList.builder(
                itemCount: day.exercises.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.fromLTRB(16, index == 0 ? 12 : 8, 16, 8),
                  child: _ExerciseCard(
                    exercise: day.exercises[index],
                    logged: session.setsFor(day.exercises[index].exerciseId),
                    strings: strings,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
        // Both actions stay on screen. A pain button you have to scroll an
        // exercise list to reach is not a safety control, and a finish
        // button below the last set is one the user hunts for mid-workout.
        Material(
          elevation: 3,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: UiKeys.sessionPain,
                      onPressed: () => _reportPain(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      icon: const Icon(Icons.healing_outlined, size: 18),
                      label: Text(l10n.sessionPainButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: UiKeys.sessionFinish,
                      onPressed: () => _finish(context, ref),
                      child: Text(l10n.sessionFinish),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Logs the pain and says what that means, after confirming.
  ///
  /// Confirmed because it is a one-way flag, and worded so that the app is
  /// never the thing telling somebody to carry on.
  Future<void> _reportPain(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    // Taken before the dialog, not after it: a ref read through a widget
    // that has gone away in the meantime throws.
    final sessions = ref.read(sessionControllerProvider);
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
            key: UiKeys.sessionPainConfirm,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.sessionPainConfirm),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await sessions.reportPain();
    }
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final sessions = ref.read(sessionControllerProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sessionDiscardTitle),
        content: Text(l10n.sessionDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.planCancel),
          ),
          FilledButton(
            key: UiKeys.sessionDiscardConfirm,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.sessionDiscardConfirm),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await sessions.discard();
      await navigator.maybePop();
    }
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) =>
      runFinishFlow(context, ref);
}

class _PainBanner extends StatelessWidget {
  const _PainBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.healing_outlined, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.sessionPainBadge,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One exercise: what was asked for, what has been done, and the fields for
/// the next set.
class _ExerciseCard extends ConsumerStatefulWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.logged,
    required this.strings,
  });

  final PlannedExercise exercise;
  final List<LoggedSet> logged;
  final PlanStrings strings;

  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  late final TextEditingController _amount;
  late final TextEditingController _weight;
  String? _error;

  bool get _isHold => widget.exercise.metric == MetricType.holdSeconds;

  @override
  void initState() {
    super.initState();
    // Prefilled with the target, because the common case is doing what the
    // plan said. Typing is then a correction rather than data entry.
    _amount = TextEditingController(
      text: '${_isHold ? widget.exercise.holdSeconds ?? 0 : widget.exercise.repsMax ?? 0}',
    );
    final target = widget.exercise.targetWeightKg;
    _weight = TextEditingController(
      text: target == null ? '' : widget.strings.weight(target),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exercise = widget.exercise;
    final done = widget.logged.length;
    final target = exercise.targetWeightKg;

    return Card(
      key: UiKeys.sessionExercise(exercise.exerciseId),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.strings.exercise(exercise.exerciseId),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                // Only on the movements the coach has rules for. An offer
                // to check the camera on an exercise it cannot judge is a
                // promise the next milestones would have to break.
                if (ref.watch(catalogProvider).require(exercise.exerciseId).camera !=
                    null)
                  IconButton(
                    key: UiKeys.sessionCoach(exercise.exerciseId),
                    icon: const Icon(Icons.videocam_outlined),
                    tooltip: l10n.coachOpen,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => CoachScreen(
                          exerciseId: exercise.exerciseId,
                          // What turns the camera check into a set runner:
                          // with a prescription and a set number it can
                          // write what it watched into the session.
                          planned: exercise,
                          setIndex: widget.logged.length,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.strings.prescription(exercise)} · '
              '${target == null ? l10n.sessionNoTarget : l10n.sessionTargetWeight(widget.strings.weight(target))}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.sessionSetsDone(done, exercise.sets),
              style: theme.textTheme.labelLarge,
            ),
            if (widget.logged.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final set in widget.logged)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(widget.strings.loggedSet(set)),
                    ),
                ],
              ),
            ],
            if (done >= exercise.sets)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.sessionExerciseDone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: UiKeys.sessionReps(exercise.exerciseId),
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText:
                            _isHold ? l10n.sessionHoldLabel : l10n.sessionRepsLabel,
                        errorText: _error,
                      ),
                    ),
                  ),
                  if (!_isHold) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: UiKeys.sessionWeight(exercise.exerciseId),
                        controller: _weight,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.sessionWeightLabel,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                key: UiKeys.sessionSaveSet(exercise.exerciseId),
                onPressed: _save,
                child: Text(l10n.sessionLogSet(done + 1)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.sessionNumberRequired);
      return;
    }

    // Blank means bodyweight, which is a real answer rather than a mistake.
    final raw = _weight.text.trim();
    final weight = raw.isEmpty ? null : double.tryParse(raw);
    if (raw.isNotEmpty && weight == null) {
      setState(() => _error = l10n.sessionNumberRequired);
      return;
    }

    setState(() => _error = null);
    await ref.read(sessionControllerProvider).logSet(
          exerciseId: widget.exercise.exerciseId,
          setIndex: widget.logged.length,
          reps: _isHold ? null : amount,
          holdSeconds: _isHold ? amount : null,
          weightKg: weight,
        );
  }
}
