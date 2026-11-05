import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  // The database has to be opened and this installation's id read before
  // anything builds a repository; see bootstrap().
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(overrides: await bootstrap(), child: const SpottrApp()),
  );
}
