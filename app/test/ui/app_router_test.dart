import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/domain/user_profile.dart';
import 'package:spottr/ui/common/ui_keys.dart';
import 'package:spottr/ui/onboarding/onboarding_screen.dart';
import 'package:spottr/ui/plan/plan_screen.dart';

import '../support/profiles.dart';
import '../support/pump.dart';

/// What the user sees first is decided by two things only: whether a
/// profile exists, and whether it cleared the disclaimer. Everything else
/// is a screen's own business.
void main() {
  testWidgets('shows a loading state while the profile is unknown',
      (tester) async {
    await pumpApp(
      tester,
      profileStream: () => const Stream.empty(),
      settled: false,
    );

    expect(find.byKey(UiKeys.loading), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(PlanScreen), findsNothing);
  });

  testWidgets('sends a device with no profile to onboarding', (tester) async {
    await pumpApp(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('keeps a profile that never accepted the disclaimer in '
      'onboarding', (tester) async {
    // The disclaimer is a gate, not a page. A profile that somehow exists
    // without it goes back through onboarding rather than into the app.
    final profile = testProfile();
    expect(profile.hasAcceptedDisclaimer, isFalse);

    await pumpApp(tester, profile: profile);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byKey(UiKeys.disclaimerAccept), findsOneWidget);
  });

  testWidgets('sends an onboarded profile to the plan', (tester) async {
    await pumpApp(tester, profile: onboardedProfile());

    expect(find.byType(PlanScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('shows a recoverable error if the profile cannot be read',
      (tester) async {
    await pumpApp(
      tester,
      profileStream: () => Stream<UserProfile?>.error(
        const FormatException('corrupt row'),
      ),
    );

    expect(find.byKey(UiKeys.errorPanel), findsOneWidget);
    expect(find.byKey(UiKeys.retry), findsOneWidget);
  });

  testWidgets('retrying re-reads the profile', (tester) async {
    // A flag the test flips, rather than a count of how often the stream
    // was built: what matters is that retrying reads again, not how many
    // subscriptions the framework makes along the way.
    var failing = true;

    await pumpApp(
      tester,
      profileStream: () => failing
          ? Stream<UserProfile?>.error(const FormatException('once'))
          : Stream.value(onboardedProfile()),
    );
    expect(find.byKey(UiKeys.errorPanel), findsOneWidget);

    failing = false;

    await tester.tap(find.byKey(UiKeys.retry));
    await tester.pumpAndSettle();

    expect(find.byType(PlanScreen), findsOneWidget);
  });
}
