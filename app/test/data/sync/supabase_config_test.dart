import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/sync/supabase_config.dart';

/// Where the project's address comes from, and what happens when it is
/// wrong. Three of these five are about a build command somebody typed by
/// hand, which is the only way these values ever arrive.
void main() {
  test('a build with neither value simply has no sync', () {
    // Not an error. A build without a project is the ordinary local-first
    // app, and it should say so rather than refuse to start.
    expect(SupabaseConfig.parse(url: '', anonKey: ''), isNull);
  });

  test('a build with both is configured, with only the origin kept', () {
    // A trailing path here would end up in the middle of every URL the
    // stores build, which fails as a 404 on the first request rather than
    // as a configuration error.
    final config = SupabaseConfig.parse(
      url: 'https://abc.supabase.co/rest/v1/',
      anonKey: 'anon-key',
    );

    expect(config!.url, Uri.parse('https://abc.supabase.co'));
    expect(config.anonKey, 'anon-key');
  });

  test('half a configuration is an error, not a quiet absence', () {
    // It is a mistake in a build command. Read as "no sync configured" it
    // would ship as a feature that silently does nothing.
    expect(
      () => SupabaseConfig.parse(url: 'https://abc.supabase.co', anonKey: ''),
      throwsArgumentError,
    );
    expect(
      () => SupabaseConfig.parse(url: '', anonKey: 'anon-key'),
      throwsArgumentError,
    );
  });

  test('plain http is refused', () {
    // An access token over HTTP is an access token in the clear. The one
    // thing worse than no sync is a sync that hands the credential to
    // somebody's café wifi.
    expect(
      () => SupabaseConfig.parse(
        url: 'http://abc.supabase.co',
        anonKey: 'anon-key',
      ),
      throwsArgumentError,
    );
  });

  test('something that is not a URL is refused', () {
    expect(
      () => SupabaseConfig.parse(url: 'abc.supabase.co', anonKey: 'k'),
      throwsArgumentError,
    );
  });
}
