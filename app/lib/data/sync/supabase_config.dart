import 'package:meta/meta.dart';

/// The Supabase project this build talks to.
///
/// Passed in with `--dart-define` rather than committed, because the
/// repository is public. The anon key is designed to ship inside a client —
/// row level security is what protects the data, not the key — but a key in
/// a public repository is still a key somebody can point at the project's
/// auth endpoint, which is a bill rather than a breach.
///
/// Absent is a legitimate state: a build with no project is a build where
/// sync is simply not offered, and everything else works exactly as before.
@immutable
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  /// The project's base URL, e.g. `https://abc.supabase.co`.
  final Uri url;

  final String anonKey;

  /// Read from the build's `--dart-define` values.
  static SupabaseConfig? fromEnvironment() {
    return parse(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  /// The same rules, without reaching for build constants.
  ///
  /// Null for a build that was given neither value. Half of one is an
  /// **error**, loudly, at startup: it is a mistake in a build command, and
  /// treating it as "no sync configured" would hide it behind a feature
  /// quietly not working.
  static SupabaseConfig? parse({
    required String url,
    required String anonKey,
  }) {
    if (url.isEmpty && anonKey.isEmpty) return null;

    if (url.isEmpty || anonKey.isEmpty) {
      throw ArgumentError(
        'SUPABASE_URL and SUPABASE_ANON_KEY go together: this build has '
        '${url.isEmpty ? 'only the key' : 'only the URL'}',
      );
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.host.isEmpty) {
      throw ArgumentError.value(url, 'SUPABASE_URL', 'is not a URL');
    }
    if (parsed.scheme != 'https') {
      // An access token over plain HTTP is an access token in the clear,
      // and the one thing worse than no sync is a sync that leaks the
      // credential to somebody's café wifi.
      throw ArgumentError.value(url, 'SUPABASE_URL', 'must be https');
    }

    return SupabaseConfig(
      // Only the origin: the REST and auth paths are the stores' business,
      // and a trailing path here would end up in the middle of every URL
      // they build.
      url: Uri(scheme: parsed.scheme, host: parsed.host, port: parsed.hasPort ? parsed.port : null),
      anonKey: anonKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SupabaseConfig &&
      other.url == url &&
      other.anonKey == anonKey;

  @override
  int get hashCode => Object.hash(url, anonKey);

  @override
  String toString() => 'SupabaseConfig($url)';
}
