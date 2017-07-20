// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library dart_dev.src.tasks.task;

import 'dart:async';

abstract class Task {
  bool successful;
  Future<TaskResult> get done;
}

abstract class TaskResult {
  bool _successful;
  TaskResult.fail() : _successful = false;
  TaskResult.success() : _successful = true;
  bool get successful => _successful;

  static Future<TaskResult> fromList(List<Future<TaskResult>> tasks) async {
    TaskResult lastTask;
    for (Future<TaskResult> task in tasks) {
      var result = await task;
      if (!result.successful) {
        return result;
      }
      lastTask = result;
    }
    return lastTask;
  }
}
