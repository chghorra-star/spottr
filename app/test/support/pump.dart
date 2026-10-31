import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_engine/plan_engine.dart';
import 'package:spottr/app.dart';
import 'package:spottr/di/providers.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/domain/workout_session.dart';
import 'package:spottr/l10n/app_localizations.dart';
import 'package:spottr/theme/app_theme.dart';

/// Boots the app with the data layer stubbed out.
///
/// Widget tests deliberately do not touch SQLite. A widget test that waits
/// on a real database read spends its life fighting the fake clock a widget
/// test runs under — and it would be testing the repositories, which have
/// their own tests against a real in-memory database. What these tests are
/// for is what the screen shows and what it asks for.
Future<void> pumpApp(
  WidgetTester tester, {
  UserProfile? profile,
  WeekPlan? plan,
  WorkoutSession? session,
  Stream<UserProfile?> Function()? profileStream,
  Stream<WeekPlan?> Function()? planStream,
  Stream<WorkoutSession?> Function()? sessionStream,
  List<Override> overrides = const [],
  bool settled = true,
}) async {
  // The two data streams are parameters rather than overrides the caller
  // passes, because overriding the same provider twice in one scope is an
  // error — and a test that wants an error or a never-ending stream still
  // wants everything else wired normally. They are builders so that
  // invalidating the provider, which is what the retry button does, runs
  // them again.
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(
          (ref) => (profileStream ?? () => Stream.value(profile))(),
        ),
        activePlanProvider.overrideWith(
          (ref) => (planStream ?? () => Stream.value(plan))(),
        ),
        activeSessionProvider.overrideWith(
          (ref) => (sessionStream ?? () => Stream.value(session))(),
        ),
        ...overrides,
      ],
      child: const SpottrApp(),
    ),
  );
  if (settled) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Mounts one screen as the whole app, with the data layer stubbed out.
///
/// For screens the app reaches by pushing a route: mounting them directly
/// keeps the test about that screen instead of about the taps that lead to
/// it, which are covered where those taps live.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  WeekPlan? plan,
  WorkoutSession? session,
  Stream<WeekPlan?> Function()? planStream,
  Stream<WorkoutSession?> Function()? sessionStream,
  List<Override> overrides = const [],
  bool settled = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activePlanProvider.overrideWith(
          (ref) => (planStream ?? () => Stream.value(plan))(),
        ),
        activeSessionProvider.overrideWith(
          (ref) => (sessionStream ?? () => Stream.value(session))(),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark,
        home: screen,
      ),
    ),
  );
  if (settled) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Mounts one widget with the app's localizations and theme.
///
/// For the question widgets, which are deliberately plain and have no
/// opinion about where their value is stored.
Future<void> pumpWidgetUnderTest(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view, then taps it.
///
/// Onboarding steps and the profile form are taller than a test viewport,
/// and a tap on an off-screen widget is a confusing failure rather than a
/// useful one.
/// [scrollable] is needed once a route has been pushed: the screen
/// underneath is still in the tree with its own scroll view, and
/// `scrollUntilVisible` refuses to guess between them.
Future<void> scrollAndTap(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
}) async {
  if (!tester.any(finder)) {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: scrollable,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
