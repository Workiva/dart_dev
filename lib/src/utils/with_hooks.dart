import '../dart_dev_tool.dart';
import '../tools/aggregate_tool.dart';

AggregateTool withHooks(DevTool tool,
        {List<DevTool> before, List<DevTool> after}) =>
    AggregateTool(tool)
      ..before = before
      ..after = after;
