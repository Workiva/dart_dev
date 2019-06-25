import 'dart:async';
import 'dart:io';

import 'exit_process_signals.dart';

/// Ensures that the current process does not exit until the given [process]
/// exits.
///
/// This function prevents the current process from exiting by watching the exit
/// signals for the current platform (SIGINT on Windows, SIGINT and SIGTERM for
/// other platforms) and consuming them until [process] exits.
///
/// If [forwardExitSignals] is true, the exit signals received by the current
/// process will be forwarded via [process.kill]. This is only needed if the
/// given [process] was started in either the [ProcessStartMode.detached] or
/// [ProcessStartMode.detachedWithStdio] modes.
void ensureProcessExit(Process process, {bool forwardExitSignals}) {
  forwardExitSignals ??= false;
  StreamSubscription sub;
  sub = exitProcessSignals.listen((signal) async {
    if (forwardExitSignals) {
      process.kill(signal);
    }
    await process.exitCode;
    await sub?.cancel();
    sub = null;
  });
  process.exitCode.then((_) {
    sub?.cancel();
    sub = null;
  });
}
