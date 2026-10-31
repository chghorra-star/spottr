import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_engine/plan_engine.dart';

import '../../di/providers.dart';
import '../../domain/user_profile.dart';
import '../../l10n/app_localizations.dart';
import '../common/ui_keys.dart';
import 'disclaimer_step.dart';
import 'questions.dart';

/// Collects a profile, one question at a time, and builds the first plan.
///
/// The disclaimer is the first step and cannot be skipped: until it is
/// accepted the only button on screen is the one that accepts it. The run
/// days question appears only for the hybrid goal, which is why the step
/// list is derived from the draft rather than fixed.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({this.existing, super.key});

  /// A profile that exists but has not cleared the disclaimer, so the
  /// user's earlier answers are not thrown away.
  final UserProfile? existing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late UserProfile _draft = widget.existing ?? UserProfile.starting();
  int _index = 0;
  bool _saving = false;
  Object? _error;

  List<_StepId> get _steps => [
        _StepId.disclaimer,
        _StepId.goal,
        if (_draft.goal == Goal.hybrid) _StepId.runDays,
        _StepId.schedule,
        _StepId.level,
        _StepId.body,
        _StepId.injuries,
        _StepId.location,
        _StepId.coach,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _steps;
    // Answering the goal question can remove the run days step, so the
    // index has to be re-checked rather than trusted.
    final index = _index.clamp(0, steps.length - 1);
    final step = steps[index];
    final isLast = index == steps.length - 1;
    final canAdvance = step != _StepId.disclaimer || _draft.hasAcceptedDisclaimer;

    return Column(
      key: UiKeys.onboarding,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onboardingProgress(index + 1, steps.length),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: (index + 1) / steps.length),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: _body(step),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '$_error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (index > 0)
                  TextButton(
                    key: UiKeys.onboardingBack,
                    onPressed: _saving ? null : () => setState(() => _index--),
                    child: Text(l10n.onboardingBack),
                  ),
                const Spacer(),
                FilledButton(
                  key: UiKeys.onboardingNext,
                  onPressed: !canAdvance || _saving
                      ? null
                      : isLast
                          ? _finish
                          : () => setState(() => _index = index + 1),
                  child: Text(
                    isLast ? l10n.onboardingFinish : l10n.onboardingNext,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(_StepId step) {
    void update(UserProfile draft) => setState(() => _draft = draft);

    return switch (step) {
      _StepId.disclaimer => DisclaimerStep(
          accepted: _draft.hasAcceptedDisclaimer,
          onAccept: () => update(
            _draft.copyWith(disclaimerAcceptedAt: DateTime.now().toUtc()),
          ),
        ),
      _StepId.goal => GoalQuestion(draft: _draft, onChanged: update),
      _StepId.runDays => RunDaysQuestion(draft: _draft, onChanged: update),
      _StepId.schedule => ScheduleQuestion(draft: _draft, onChanged: update),
      _StepId.level => LevelQuestion(draft: _draft, onChanged: update),
      _StepId.body => BodyQuestion(draft: _draft, onChanged: update),
      _StepId.injuries => InjuriesQuestion(draft: _draft, onChanged: update),
      _StepId.location => LocationQuestion(draft: _draft, onChanged: update),
      _StepId.coach => CoachQuestion(draft: _draft, onChanged: update),
    };
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Saving the profile also builds the first plan, so by the time the
      // profile stream re-emits and routing swaps in the plan screen, there
      // is a plan there to show.
      await ref.read(profileControllerProvider).save(_draft);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

enum _StepId {
  disclaimer,
  goal,
  runDays,
  schedule,
  level,
  body,
  injuries,
  location,
  coach,
}
