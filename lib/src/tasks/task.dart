library dart_dev.src.tasks.task;

import 'dart:async';

abstract class Task {
  Future get done;
  bool successful;
}
