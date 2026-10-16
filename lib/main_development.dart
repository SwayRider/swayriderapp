import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'main.dart';

void main() {
  Logger.root.level = Level.ALL;
  // Without a listener the log records are dropped; show them in debug runs.
  Logger.root.onRecord.listen(
    (r) => debugPrint('${r.level.name} ${r.loggerName}: ${r.message}'),
  );
  runApp(MultiProvider(providers: providerDev, child: const MainApp()));
}
