import '../dart_dev_tool.dart';
import '../tools/aggregate_tool.dart';

AggregateTool compose(DevTool tool,
        {List<DevTool> before, List<DevTool> after}) =>
    AggregateTool(tool)
      ..before = before
      ..after = after;
