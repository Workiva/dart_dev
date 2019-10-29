import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';

Stream<ProcessSignal> get exitProcessSignals => Platform.isWindows
    ? ProcessSignal.sigint.watch()
    : StreamGroup.merge(
        [ProcessSignal.sigterm.watch(), ProcessSignal.sigint.watch()]);
