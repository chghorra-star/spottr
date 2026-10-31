import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_engine/plan_engine.dart';

import '../../di/providers.dart';
import '../../domain/user_profile.dart';
import '../../l10n/app_localizations.dart';
import '../common/async_view.dart';
import '../common/ui_keys.dart';
import '../onboarding/questions.dart';

/// The same questions as onboarding, in one scroll, with a save button.
///
/// Saving rebuilds the week when an answer the generator reads has changed,
/// and leaves it alone when the change was cosmetic. The warning at the top
/// says so, because a user who edits their coach voice should not be afraid
/// of losing the swaps they made.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProfile? _draft;
  bool _saving = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stored = ref.watch(profileProvider);

    return Scaffold(
      key: UiKeys.profileScreen,
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          TextButton(
            key: UiKeys.profileSave,
            onPressed: _draft == null || _saving ? null : _save,
            child: Text(l10n.profileSave),
          ),
        ],
      ),
      body: AsyncView<UserProfile?>(
        value: stored,
        onRetry: () => ref.invalidate(profileProvider),
        builder: (context, data) {
          if (data == null) return const SizedBox.shrink();
          final draft = _draft ?? data;
          return _Form(
            draft: draft,
            error: _error,
            onChanged: (next) => setState(() => _draft = next),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileControllerProvider).save(draft);
      if (mounted) {
        setState(() => _draft = null);
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.draft,
    required this.onChanged,
    required this.error,
  });

  final UserProfile draft;
  final DraftChanged onChanged;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.profileRebuildWarning,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            '$error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        GoalQuestion(draft: draft, onChanged: onChanged),
        if (draft.goal == Goal.hybrid) ...[
          const SizedBox(height: 32),
          RunDaysQuestion(draft: draft, onChanged: onChanged),
        ],
        const SizedBox(height: 32),
        ScheduleQuestion(draft: draft, onChanged: onChanged),
        const SizedBox(height: 32),
        LevelQuestion(draft: draft, onChanged: onChanged),
        const SizedBox(height: 32),
        LocationQuestion(draft: draft, onChanged: onChanged),
        const SizedBox(height: 32),
        InjuriesQuestion(draft: draft, onChanged: onChanged),
        const SizedBox(height: 32),
        BodyQuestion(draft: draft, onChanged: onChanged),
        const SizedBox(height: 32),
        CoachQuestion(draft: draft, onChanged: onChanged),
        const SizedBox(height: 48),
      ],
    );
  }
}
