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
///
/// At the bottom, on a device nobody has signed in on, is the only way to
/// delete everything the app holds. See [_ProfileScreenState._delete] for
/// why it lives here rather than on the account screen.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProfile? _draft;
  bool _saving = false;
  bool _deleting = false;
  Object? _error;
  String? _deleteError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stored = ref.watch(profileProvider);

    // Offered only where there is no other door and nothing has left the
    // phone — which are the same condition. A device with an owner has the
    // account screen's erase, worded for handing a phone on; a device
    // without one has never synced a row anywhere. While the answer is
    // still unknown the control stays away rather than appearing and then
    // vanishing.
    final account = ref.watch(accountProvider);
    final unclaimed = account.hasValue && account.value?.owner == null;
    final busy = _saving || _deleting;

    return Scaffold(
      key: UiKeys.profileScreen,
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          TextButton(
            key: UiKeys.profileSave,
            onPressed: _draft == null || busy ? null : _save,
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
            onDelete: unclaimed && !busy ? _delete : null,
            deleteError: _deleteError,
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

  /// Deleting everything this device holds, after asking.
  ///
  /// This is here rather than on the account screen because the account
  /// screen does not exist for everybody: a build with no Supabase project
  /// shows no sign-in and claims no owner, so its erase — the way out of a
  /// device that holds somebody else's training — never appears. Without
  /// this control such a phone holds a profile, a plan and every session
  /// ever logged, with no way to delete any of it from inside the app.
  ///
  /// The mechanism is the same `TrainingEraser` either way. What differs is
  /// the sentence: this one can say there is no copy anywhere, because it
  /// is only ever shown on a device that has never belonged to an account.
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileDeleteConfirmTitle),
        content: Text(l10n.profileDeleteConfirmBody),
        actions: [
          TextButton(
            key: UiKeys.profileDeleteCancel,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.profileDeleteCancel),
          ),
          FilledButton(
            key: UiKeys.profileDeleteConfirm,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.profileDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() {
      _deleting = true;
      _deleteError = null;
    });
    try {
      await ref.read(eraseControllerProvider).erase();
      // Leaving, rather than reporting. There is no profile left for this
      // form to show, and the router underneath is already switching to
      // onboarding now the row is gone — which is the clearest statement
      // that it worked the app can make.
      if (mounted) Navigator.of(context).pop();
    } on Object catch (_) {
      // One sentence for every failure, because what matters is not what
      // went wrong but what the phone is left holding. The eraser releases
      // the owner last precisely so that answer is all of it, try again.
      if (mounted) setState(() => _deleteError = l10n.profileDeleteFailed);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.draft,
    required this.onChanged,
    required this.error,
    required this.onDelete,
    required this.deleteError,
  });

  final UserProfile draft;
  final DraftChanged onChanged;
  final Object? error;

  /// Null on a device that has an account, where the way to do this is the
  /// account screen's erase, and while a delete is already running.
  final VoidCallback? onDelete;

  final String? deleteError;

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
        if (onDelete != null || deleteError != null)
          ..._deleteSection(l10n, theme),
        const SizedBox(height: 48),
      ],
    );
  }

  /// The last thing on the form, below a rule, in the plainest control the
  /// screen has. It is the one irreversible thing here, and a filled button
  /// inviting the tap would be the wrong shape for it.
  List<Widget> _deleteSection(AppLocalizations l10n, ThemeData theme) {
    return [
      const SizedBox(height: 40),
      const Divider(),
      const SizedBox(height: 16),
      Text(l10n.profileDeleteTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(
        l10n.profileDeleteExplain,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      TextButton(
        key: UiKeys.profileDelete,
        onPressed: onDelete,
        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
        child: Text(l10n.profileDelete),
      ),
      if (deleteError != null) ...[
        const SizedBox(height: 8),
        Text(
          deleteError!,
          key: UiKeys.profileDeleteError,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ],
    ];
  }
}
