import 'package:exercise_library/exercise_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/plan_strings.dart';
import '../common/choice_tile.dart';
import '../common/ui_keys.dart';

/// Offers the exercises that could take this one's place.
///
/// The list comes from the catalog's curated alternatives, filtered to what
/// the user can actually do — so an injury or a missing dumbbell can never
/// be swapped around by accident.
Future<void> showSwapSheet(
  BuildContext context, {
  required int weekday,
  required String exerciseId,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SwapSheet(
        weekday: weekday,
        exerciseId: exerciseId,
      ),
    );

class _SwapSheet extends ConsumerStatefulWidget {
  const _SwapSheet({required this.weekday, required this.exerciseId});

  final int weekday;
  final String exerciseId;

  @override
  ConsumerState<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends ConsumerState<_SwapSheet> {
  late Future<List<Exercise>> _alternatives;

  @override
  void initState() {
    super.initState();
    _alternatives = ref.read(planControllerProvider).alternativesFor(
          weekday: widget.weekday,
          exerciseId: widget.exerciseId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final strings = PlanStrings.of(context, ref.watch(catalogProvider));

    return SafeArea(
      child: Padding(
        key: UiKeys.swapSheet,
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<List<Exercise>>(
          future: _alternatives,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  key: UiKeys.loading,
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final alternatives = snapshot.data!;
            return SingleChildScrollView(
              child: QuestionSection(
                title: l10n.swapTitle(strings.exercise(widget.exerciseId)),
                body: alternatives.isEmpty
                    ? l10n.swapNoAlternatives
                    : l10n.swapBody,
                children: [
                  if (alternatives.isEmpty)
                    const SizedBox(key: UiKeys.swapEmpty, height: 0),
                  for (final alternative in alternatives)
                    ChoiceTile(
                      key: UiKeys.swapOption(alternative.id),
                      title: strings.exercise(alternative.id),
                      detail: l10n.swapTargets(
                        strings.muscleList(alternative.primaryMuscles),
                      ),
                      selected: false,
                      trailing: alternative.isCameraSupported
                          ? Icon(
                              Icons.videocam_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => _apply(alternative.id),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _apply(String replacementId) async {
    final navigator = Navigator.of(context);
    await ref.read(planControllerProvider).swap(
          weekday: widget.weekday,
          exerciseId: widget.exerciseId,
          replacementId: replacementId,
        );
    if (navigator.canPop()) navigator.pop();
  }
}
