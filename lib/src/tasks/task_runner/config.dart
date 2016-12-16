import 'package:dart_dev/src/tasks/config.dart';

const List<String> defaultTasks = const [
  'pub run dart_dev format --check',
  'pub run dart_dev analyze'
];

class TaskRunnerConfig extends TaskConfig {
  List<String> tasksToRun = defaultTasks;
}
