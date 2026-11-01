/// The accuracy harness: replay labelled landmark fixtures through the real
/// coach engine and report what it counted.
///
/// Pure Dart with no Flutter anywhere, which is the point: the whole
/// rep-counting and form-analysis stack can be measured under `dart test`
/// with no device attached. What it can honestly claim depends entirely on
/// where the fixtures came from — see `FixtureSource`.
library;

export 'src/fixture.dart';
export 'src/margins.dart';
export 'src/robustness.dart';
export 'src/replay.dart';
export 'src/suite.dart';
export 'src/synthetic.dart';
export 'src/fixture_io.dart';
export 'src/report.dart';
