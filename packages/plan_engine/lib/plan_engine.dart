/// Workout plan generation and adaptive progression.
///
/// Rule-based templates per goal and training frequency, personalized by
/// level, equipment and injuries. Entirely deterministic: the same request
/// always produces the same plan, which is what makes golden tests possible.
///
/// Pure Dart: nothing here imports Flutter.
library;

export 'src/day_rules.dart';
export 'src/generator.dart';
export 'src/goal.dart';
export 'src/plan_edits.dart';
export 'src/plan_request.dart';
export 'src/scheduler.dart';
export 'src/templates.dart';
export 'src/week_plan.dart';
