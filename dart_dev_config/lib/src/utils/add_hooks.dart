import '../dart_dev_tool.dart';
import '../tools/wrapped_tool.dart';

WrappedTool addHooks(DevTool tool,
        {List<DevTool> before, List<DevTool> after}) =>
    WrappedTool(tool)
      ..before = before
      ..after = after;
