import 'package:coach_engine/coach_engine.dart';
import 'package:test/test.dart';

void main() {
  test('three styles, and the default is one of them', () {
    expect(CoachStyle.values, hasLength(3));
    expect(CoachStyle.values, contains(CoachStyle.fallback));
  });

  test('names are stable, because they are persisted', () {
    // Profiles store the name, so renaming a value is a data migration.
    expect(
      CoachStyle.values.map((s) => s.name),
      ['hype', 'calm', 'tough'],
    );
  });
}
