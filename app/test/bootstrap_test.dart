import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/bootstrap.dart';
import 'package:spottr/data/local/database.dart';
import 'package:spottr/di/providers.dart';

import 'support/profiles.dart';
import 'support/test_database.dart';

/// `bootstrap()` exists to close one gap, and the last test here is the one
/// that proves it closed: every row this device writes is stamped with this
/// installation's own id. Until M10 every install stamped `'local'`, which
/// made the conflict rule's tie-break unable to break anything — two edits
/// claiming the same instant resolved to "keep mine" on both devices and
/// stayed different for ever.
void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('reads an install id and hands it to the app', () async {
    final container = ProviderContainer.test(
      overrides: await bootstrap(database: db),
    );

    expect(container.read(installIdProvider), isNotEmpty);
  });

  test('the same id on the next launch', () async {
    final first = ProviderContainer.test(overrides: await bootstrap(database: db));
    final second =
        ProviderContainer.test(overrides: await bootstrap(database: db));

    expect(
      second.read(installIdProvider),
      first.read(installIdProvider),
    );
  });

  test('a scope without it refuses to build a repository', () async {
    // Loudly, rather than falling back to a constant. A default that worked
    // would be a default that silently stamped rows with the wrong device,
    // and nothing downstream could tell. Matched on the message because
    // Riverpod wraps the error, and the message is the part that has to
    // name what to fix.
    final container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(db)],
    );

    expect(
      () => container.read(profileRepositoryProvider),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('installIdProvider'),
        ),
      ),
    );
  });

  test('a row written after it says which device wrote it', () async {
    final container = ProviderContainer.test(
      overrides: await bootstrap(database: db),
    );
    final installId = container.read(installIdProvider);

    await container.read(profileRepositoryProvider).save(testProfile());

    final stored = await db.select(db.profiles).getSingle();
    expect(stored.deviceId, installId);
    expect(stored.deviceId, isNot('local'));
  });
}
