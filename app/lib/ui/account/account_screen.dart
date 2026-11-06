import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../data/sync/sync_account.dart';
import '../../di/providers.dart';
import '../../l10n/account_strings.dart';
import '../../l10n/app_localizations.dart';
import '../common/async_view.dart';
import '../common/ui_keys.dart';

/// Signing in, signing out, and syncing now.
///
/// The screen leads with what is true whether or not anybody signs in:
/// Spottr works without an account, and nothing from the camera is ever
/// uploaded. Sync is a convenience for a second device, not the thing the
/// app is for, and a screen that opened with a sign-in wall would say the
/// opposite.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _busy = false;
  String? _error;
  List<String> _result = const [];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final configured = ref.watch(supabaseConfigProvider) != null;

    return Scaffold(
      key: UiKeys.accountScreen,
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: configured
          ? AsyncView<AccountState>(
              value: ref.watch(accountProvider),
              onRetry: () => ref.invalidate(accountProvider),
              builder: (context, state) => _Body(
                state: state,
                email: _email,
                password: _password,
                busy: _busy,
                error: _error,
                result: _result,
                onSignIn: () => _authenticate(signUp: false),
                onSignUp: () => _authenticate(signUp: true),
                onSignOut: _signOut,
                onSync: _sync,
                onErase: _erase,
              ),
            )
          : const _Unavailable(),
    );
  }

  Future<void> _authenticate({required bool signUp}) async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    final password = _password.text;

    // Checked here rather than sent: an empty field is a question for the
    // user, and a round trip to be told so is slower and less clear.
    if (email.isEmpty) return setState(() => _error = l10n.accountEmailMissing);
    if (password.isEmpty) {
      return setState(() => _error = l10n.accountPasswordMissing);
    }

    final controller = ref.read(accountControllerProvider);
    if (controller == null) return;

    setState(() {
      _busy = true;
      _error = null;
      _result = const [];
    });
    try {
      if (signUp) {
        await controller.signUp(email: email, password: password);
      } else {
        await controller.signIn(email: email, password: password);
      }
      _password.clear();
      // Straight into a sync. Somebody who has just signed in did it to get
      // their training onto this device; a screen that then sat there
      // waiting to be told to sync reads as not having worked.
      if (mounted) await _sync();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = AccountStrings.of(context).authError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final controller = ref.read(accountControllerProvider);
    if (controller == null) return;

    setState(() {
      _busy = true;
      _error = null;
      _result = const [];
    });
    try {
      await controller.signOut();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Erasing this device's training, after asking.
  ///
  /// Asked rather than offered twice, and the question says what survives:
  /// somebody tapping this is deleting their own training off a phone, and
  /// the two things they need to know are that this device cannot undo it
  /// and that their account still has whatever had synced.
  Future<void> _erase() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountEraseConfirmTitle),
        content: Text(l10n.accountEraseConfirmBody),
        actions: [
          TextButton(
            key: UiKeys.accountEraseCancel,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.accountEraseCancel),
          ),
          FilledButton(
            key: UiKeys.accountEraseConfirm,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.accountEraseConfirmAction),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    final controller = ref.read(accountControllerProvider);
    if (controller == null) return;

    setState(() {
      _busy = true;
      _error = null;
      _result = const [];
    });
    try {
      await controller.eraseTraining();
      // The next person's screen. Leaving the previous one's address in the
      // field would be a small thing to get wrong on this particular screen.
      _email.clear();
      _password.clear();
      if (mounted) setState(() => _result = [l10n.accountErased]);
    } on Object catch (_) {
      // One sentence for every failure, because what the user needs to know
      // is not what went wrong but what the device is left holding — and
      // the owner is released last precisely so that answer is "still
      // yours, try again".
      if (mounted) setState(() => _error = l10n.accountEraseFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    final controller = ref.read(accountControllerProvider);
    if (controller == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final SyncReport report = await controller.syncNow();
      if (mounted) {
        setState(
          () => _result = AccountStrings.of(context).syncResult(report),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = AccountStrings.of(context).authError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// A build with no project to sync to.
class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      key: UiKeys.accountUnavailable,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.accountUnavailableTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.accountUnavailableBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.email,
    required this.password,
    required this.busy,
    required this.error,
    required this.result,
    required this.onSignIn,
    required this.onSignUp,
    required this.onSignOut,
    required this.onSync,
    required this.onErase,
  });

  final AccountState state;
  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final String? error;
  final List<String> result;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final VoidCallback onSignOut;
  final VoidCallback onSync;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // First, before any field: the app does not need this.
        Text(
          l10n.accountLocalFirstBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (state.signedIn)
          ..._signedIn(context, l10n, theme)
        else
          ..._signedOut(context, l10n, theme),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            error!,
            key: UiKeys.accountError,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        if (result.isNotEmpty) ...[
          const SizedBox(height: 16),
          Column(
            key: UiKeys.accountResult,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in result)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(line, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ],
        // Last, and only on a device that holds somebody's training. On one
        // nobody has signed in on there is nothing to hand over and nobody
        // is stuck, and a delete-everything button on a screen about sync
        // would be a different feature wearing this one's clothes.
        if (state.owner != null) ..._erase(context, l10n, theme),
      ],
    );
  }

  List<Widget> _erase(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return [
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 16),
      Text(l10n.accountEraseTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(
        l10n.accountEraseExplain,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      // Deliberately the plainest control on the screen. It is the one
      // irreversible thing here, and a filled button inviting the tap would
      // be the wrong shape for it.
      TextButton(
        key: UiKeys.accountErase,
        onPressed: busy ? null : onErase,
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
        ),
        child: Text(l10n.accountErase),
      ),
    ];
  }

  List<Widget> _signedIn(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return [
      Text(
        l10n.accountSignedInAs(state.owner?.email ?? ''),
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 24),
      FilledButton(
        key: UiKeys.accountSyncNow,
        onPressed: busy ? null : onSync,
        child: Text(busy ? l10n.accountSyncing : l10n.accountSyncNow),
      ),
      const SizedBox(height: 8),
      TextButton(
        key: UiKeys.accountSignOut,
        onPressed: busy ? null : onSignOut,
        child: Text(l10n.accountSignOut),
      ),
    ];
  }

  List<Widget> _signedOut(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return [
      // Worth telling apart from never having signed in: one is an
      // invitation, the other a return, and the second one is reassurance
      // that the training on this device did not go anywhere.
      if (state.isReturning) ...[
        Text(
          l10n.accountSignedOutOf(state.owner?.email ?? ''),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
      ],
      TextField(
        key: UiKeys.accountEmail,
        controller: email,
        enabled: !busy,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        decoration: InputDecoration(labelText: l10n.accountEmail),
      ),
      const SizedBox(height: 16),
      TextField(
        key: UiKeys.accountPassword,
        controller: password,
        enabled: !busy,
        obscureText: true,
        decoration: InputDecoration(labelText: l10n.accountPassword),
      ),
      const SizedBox(height: 24),
      FilledButton(
        key: UiKeys.accountSignIn,
        onPressed: busy ? null : onSignIn,
        child: Text(l10n.accountSignIn),
      ),
      const SizedBox(height: 8),
      TextButton(
        key: UiKeys.accountSignUp,
        onPressed: busy ? null : onSignUp,
        child: Text(l10n.accountSignUp),
      ),
    ];
  }
}
