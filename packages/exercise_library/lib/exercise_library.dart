/// The curated exercise catalog: schema, lookup, filtering, and integrity
/// validation.
///
/// The plan generator may only pick exercises from here, and the camera coach
/// reads its rep-counter config and form rules from catalog data. Adding an
/// exercise is a data change, not a code change.
///
/// Pure Dart: nothing here imports Flutter.
library;

export 'src/camera_support.dart';
export 'src/catalog.dart';
export 'src/enums.dart';
export 'src/exercise.dart';
export 'src/standard_catalog.dart';
