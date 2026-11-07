import '../data/local/training_eraser.dart';

/// What the profile screen is allowed to ask for when somebody wants their
/// training off this phone.
///
/// An interface for the same reason as the other four controllers: widget
/// tests deliberately do not touch SQLite, and the one thing this screen
/// now does that cannot be undone is the one thing a test most needs to
/// assert without a database underneath it.
abstract interface class EraseController {
  /// Deletes everything this device holds about a person.
  Future<void> erase();
}

/// The real one, which is glue and nothing else.
///
/// Every decision worth making is in [TrainingEraser] — what goes, what is
/// kept, the order a failure leaves things in — and is tested there against
/// a real database. This exists so that the screen depends on an interface
/// rather than on that class.
class DeviceEraseController implements EraseController {
  const DeviceEraseController(this.eraser);

  final TrainingEraser eraser;

  @override
  Future<void> erase() => eraser.erase();
}
