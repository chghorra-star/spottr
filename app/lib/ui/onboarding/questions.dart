import 'package:coach_engine/coach_engine.dart';
import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_engine/plan_engine.dart';

import '../../di/providers.dart';
import '../../domain/user_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../common/choice_tile.dart';
import '../common/ui_keys.dart';

/// The onboarding questions, each a plain widget over a draft profile.
///
/// They are separate from the flow that sequences them because the profile
/// screen shows the same questions in one scroll. One definition means the
/// two screens cannot drift apart, and a change to a question's wording or
/// options lands in both.
///
/// Every question takes the whole draft and emits a whole draft. That is
/// slightly blunt, but it keeps each one stateless and makes "what did the
/// user change" a single comparison at the point where it is saved.
typedef DraftChanged = void Function(UserProfile draft);

class GoalQuestion extends ConsumerWidget {
  const GoalQuestion({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final UserProfile draft;
  final DraftChanged onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));
    return QuestionSection(
      key: UiKeys.questionGoal,
      title: AppLocalizations.of(context).stepGoalTitle,
      children: [
        for (final goal in Goal.values)
          ChoiceTile(
            key: UiKeys.choice('goal', goal.name),
            title: strings.goal(goal),
            detail: strings.goalDetail(goal),
            selected: draft.goal == goal,
            onTap: () => onChanged(draft.copyWith(goal: goal)),
          ),
      ],
    );
  }
}

class ScheduleQuestion extends StatelessWidget {
  const ScheduleQuestion({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final UserProfile draft;
  final DraftChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return QuestionSection(
      key: UiKeys.questionSchedule,
      title: l10n.stepDaysTitle,
      children: [
        Text(
          l10n.stepDaysValue(draft.daysPerWeek),
          style: theme.textTheme.titleMedium,
        ),
        Slider(
          key: UiKeys.daysSlider,
          value: draft.daysPerWeek.toDouble(),
          min: UserProfile.minDaysPerWeek.toDouble(),
          max: UserProfile.maxDaysPerWeek.toDouble(),
          divisions: UserProfile.maxDaysPerWeek - UserProfile.minDaysPerWeek,
          label: l10n.stepDaysValue(draft.daysPerWeek),
          onChanged: (value) =>
              onChanged(draft.copyWith(daysPerWeek: value.round())),
        ),
        const SizedBox(height: 24),
        Text(l10n.stepSessionTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          l10n.stepSessionValue(draft.sessionMinutes),
          style: theme.textTheme.titleMedium,
        ),
        Slider(
          key: UiKeys.minutesSlider,
          value: draft.sessionMinutes.toDouble(),
          min: UserProfile.minSessionMinutes.toDouble(),
          max: _maxSliderMinutes.toDouble(),
          // Five-minute steps: nobody plans a session to the minute.
          divisions:
              (_maxSliderMinutes - UserProfile.minSessionMinutes) ~/ 5,
          label: l10n.stepSessionValue(draft.sessionMinutes),
          onChanged: (value) =>
              onChanged(draft.copyWith(sessionMinutes: value.round())),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.stepSessionBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// The slider stops well below the model's ceiling. Two hours is already
  /// more than this app will ever program for.
  static const int _maxSliderMinutes = 120;
}

class LevelQuestion extends ConsumerWidget {
  const LevelQuestion({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final UserProfile draft;
  final DraftChanged onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));
    return QuestionSection(
      key: UiKeys.questionLevel,
      title: AppLocalizations.of(context).stepLevelTitle,
      children: [
        for (final level in Level.values)
          ChoiceTile(
            key: UiKeys.choice('level', level.name),
            title: strings.level(level),
            detail: strings.levelDetail(level),
            selected: draft.level == level,
            onTap: () => onChanged(draft.copyWith(level: level)),
          ),
      ],
    );
  }
}

/// Age, height, weight and sex. All optional, and nothing in the MVP reads
/// them — which the copy says out loud rather than implying they matter.
class BodyQuestion extends ConsumerStatefulWidget {
  const BodyQuestion({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final UserProfile draft;
  final DraftChanged onChanged;

  @override
  ConsumerState<BodyQuestion> createState() => _BodyQuestionState();
}

class _BodyQuestionState extends ConsumerState<BodyQuestion> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;

  @override
  void initState() {
    super.initState();
    _age = TextEditingController(text: _text(widget.draft.ageYears));
    _height = TextEditingController(text: _text(widget.draft.heightCm));
    _weight = TextEditingController(text: _text(widget.draft.weightKg));
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  static String _text(num? value) {
    if (value == null) return '';
    if (value is double && value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));

    return QuestionSection(
      key: UiKeys.questionBody,
      title: l10n.stepBodyTitle,
      body: l10n.stepBodyBody,
      children: [
        _numberField(
          key: UiKeys.ageField,
          controller: _age,
          label: l10n.fieldAge,
          onParsed: (value) => widget.onChanged(
            widget.draft.copyWith(
              ageYears: value?.round(),
              clearAgeYears: value == null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _numberField(
          key: UiKeys.heightField,
          controller: _height,
          label: l10n.fieldHeight,
          onParsed: (value) => widget.onChanged(
            widget.draft.copyWith(
              heightCm: value,
              clearHeightCm: value == null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _numberField(
          key: UiKeys.weightField,
          controller: _weight,
          label: l10n.fieldWeight,
          onParsed: (value) => widget.onChanged(
            widget.draft.copyWith(
              weightKg: value,
              clearWeightKg: value == null,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.fieldSex, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final sex in Sex.values)
          ChoiceTile(
            key: UiKeys.choice('sex', sex.name),
            title: strings.sex(sex),
            selected: widget.draft.sex == sex,
            onTap: () => widget.onChanged(
              // Tapping the chosen value again clears it: the question is
              // optional, so there has to be a way back to no answer.
              widget.draft.sex == sex
                  ? widget.draft.copyWith(clearSex: true)
                  : widget.draft.copyWith(sex: sex),
            ),
          ),
      ],
    );
  }

  Widget _numberField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required ValueChanged<double?> onParsed,
  }) =>
      TextField(
        key: key,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) {
          final trimmed = text.trim();
          onParsed(trimmed.isEmpty ? null : double.tryParse(trimmed));
        },
      );
}

/// The injury question.
///
/// Four checkboxes plus free text, as the brief asks. The checkboxes are
/// the ones the catalog can act on; the free text is shown back to the user
/// and never parsed, because guessing at prose here would mean guessing
/// about someone's injury.
class InjuriesQuestion extends ConsumerStatefulWidget {
  const InjuriesQuestion({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final UserProfile draft;
  final DraftChanged onChanged;

  /// The sites onboarding exposes. The enum has more, for the catalog's
  /// benefit, but asking about eight areas would make the question worse.
  static const List<BodyPart> offered = [
    BodyPart.knees,
    BodyPart.lowerBack,
    BodyPart.shoulders,
    BodyPart.wrists,
  ];

  @override
  ConsumerState<InjuriesQuestion> createState() => _InjuriesQuestionState();
}

class _InjuriesQuestionState extends ConsumerState<InjuriesQuestion> {
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.draft.injuryNotes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));

    return QuestionSection(
      key: UiKeys.questionInjuries,
      title: l10n.stepInjuriesTitle,
      body: l10n.stepInjuriesBody,
      children: [
        for (final part in InjuriesQuestion.offered)
          ChoiceTile(
            key: UiKeys.choice('injury', part.name),
            title: strings.bodyPart(part),
            multiSelect: true,
            selected: widget.draft.injuries.contains(part),
            onTap: () => widget.onChanged(
              widget.draft.copyWith(injuries: _toggled(part)),
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          key: UiKeys.injuryNotesField,
          controller: _notes,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.fieldInjuryNotes,
            helperText: l10n.fieldInjuryNotesHint,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
          onChanged: (text) {
            final trimmed = text.trim();
            widget.onChanged(
              widget.draft.copyWith(
                injuryNotes: trimmed.isEmpty ? null : trimmed,
                clearInjuryNotes: trimmed.isEmpty,
              ),
            );
          },
        ),
      ],
    );
  }

  Set<BodyPart> _toggled(BodyPart part) {
    final next = {...widget.draft.injuries};
    if (!next.remove(part)) next.add(part);
    return next;
  }
}

/// Where the user trains, and anything extra they have.
///
/// The extra-equipment list is filtered to what the chosen location does
/// not already imply: offering a full-gym member a pull-up bar would be
/// noise, and offering a bodyweight-at-home user a cable machine would be
/// a lie about what they can do.
class LocationQuestion extends ConsumerWidget {
  const LocationQuestion({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final UserProfile draft;
  final DraftChanged onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));
    final implied = draft.location.impliedEquipment;
    final offerable = [
      for (final item in Equipment.values)
        if (!implied.contains(item)) item,
    ];

    return QuestionSection(
      key: UiKeys.questionLocation,
      title: l10n.stepLocationTitle,
      children: [
        for (final location in TrainingLocation.values)
          ChoiceTile(
            key: UiKeys.choice('location', location.name),
            title: strings.location(location),
            detail: strings.locationDetail(location),
            selected: draft.location == location,
            onTap: () => onChanged(
              draft.copyWith(
                location: location,
                // Anything the new location already implies stops being
                // "extra", so the two answers can never contradict.
                extraEquipment: draft.extraEquipment
                    .difference(location.impliedEquipment),
              ),
            ),
          ),
        if (offerable.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.stepEquipmentTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.stepEquipmentBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final item in offerable)
            ChoiceTile(
              key: UiKeys.choice('equipment', item.name),
              title: strings.equipment(item),
              multiSelect: true,
              selected: draft.extraEquipment.contains(item),
              onTap: () => onChanged(
                draft.copyWith(extraEquipment: _toggled(item)),
              ),
            ),
        ],
      ],
    );
  }

  Set<Equipment> _toggled(Equipment item) {
    final next = {...draft.extraEquipment};
    if (!next.remove(item)) next.add(item);
    return next;
  }
}

/// Which days the user runs.
///
/// Only shown for the hybrid goal, and the copy is explicit that Spottr
/// does not track runs — it schedules around them.
class RunDaysQuestion extends ConsumerWidget {
  const RunDaysQuestion({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final UserProfile draft;
  final DraftChanged onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));

    return QuestionSection(
      key: UiKeys.questionRunDays,
      title: l10n.stepRunDaysTitle,
      body: l10n.stepRunDaysBody,
      children: [
        for (var weekday = 1; weekday <= 7; weekday++)
          ChoiceTile(
            key: UiKeys.choice('runDay', '$weekday'),
            title: strings.weekday(weekday),
            multiSelect: true,
            selected: draft.runWeekdays.contains(weekday),
            onTap: () => onChanged(
              draft.copyWith(runWeekdays: _toggled(weekday)),
            ),
          ),
      ],
    );
  }

  Set<int> _toggled(int weekday) {
    final next = {...draft.runWeekdays};
    if (!next.remove(weekday)) next.add(weekday);
    return next;
  }
}

class CoachQuestion extends ConsumerWidget {
  const CoachQuestion({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final UserProfile draft;
  final DraftChanged onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));

    return QuestionSection(
      key: UiKeys.questionCoach,
      title: l10n.stepCoachTitle,
      body: l10n.stepCoachBody,
      children: [
        for (final style in CoachStyle.values)
          ChoiceTile(
            key: UiKeys.choice('coach', style.name),
            title: strings.coachStyle(style),
            detail: strings.coachStyleDetail(style),
            selected: draft.coachStyle == style,
            onTap: () => onChanged(draft.copyWith(coachStyle: style)),
          ),
      ],
    );
  }
}
