import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import 'common/async_view.dart';
import 'onboarding/onboarding_screen.dart';
import 'plan/plan_screen.dart';

/// Decides what the user sees first.
///
/// Two questions, in order: is there a profile, and did it clear the
/// disclaimer. The disclaimer is a gate rather than a page — a profile that
/// exists without it goes back through onboarding, because the one thing
/// the app must not do is start coaching someone who never read it.
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      body: AsyncView(
        value: profile,
        onRetry: () => ref.invalidate(profileProvider),
        builder: (context, data) =>
            data == null || !data.hasAcceptedDisclaimer
                ? OnboardingScreen(existing: data)
                : const PlanScreen(),
      ),
    );
  }
}
