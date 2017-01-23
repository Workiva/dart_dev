import 'package:dart_dev/src/tasks/config.dart';

const List<String> defaultTasks = const [
  'pub run dart_dev format --check',
  'pub run dart_dev analyze',
  'pub run dart_dev test'
];

class TaskRunnerConfig extends TaskConfig {
  List<String> tasksToRun = defaultTasks;
}
