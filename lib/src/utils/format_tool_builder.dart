import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_dev/src/utils/orf_tool.dart';
import 'package:glob/glob.dart';

import '../../dart_dev.dart';
import 'logging.dart';

enum KnownFormatTools { FormatTool, OverReactFormatTool }

/// Visits a `dart_dev/config.dart` file and searches for a custom formatter.
///
/// Expects the configuration to be in the format of:
/// ```dart
/// import 'package:over_react_format/dart_dev_tool.dart';
///
/// final config = {
///   'format': OverReactFormatTool()
///     ..lineLength = 120,
/// };
/// ```
class FormatToolBuilder extends GeneralizingAstVisitor<void> {
  DevTool formatDevTool;

  FormatToolBuilder();

  @override
  visitMapLiteralEntry(MapLiteralEntry node) {
    super.visitMapLiteralEntry(node);

    String mapEntryKey = node.key.toSource().replaceAll("'", "");

    if (mapEntryKey != 'format') return;

    final formatterInvocation = node.value;
    formatDevTool = _detectFormatter(node.value);

    if (formatterInvocation is CascadeExpression) {
      List<Glob> excludesList = [];

      final excludeExpression =
          formatterInvocation.getCascadeByProperty('exclude');
      if (excludeExpression != null) {
        final formatterType = excludeExpression.rightHandSide;
        if (formatterType is ListLiteral) {
          excludesList =
              formatterType.elements.whereType<MethodInvocation>().where((e) {
            return e.argumentList.arguments.length == 1 &&
                e.argumentList.arguments.first is StringLiteral;
          }).map((e) {
            final path =
                (e.argumentList.arguments.first as StringLiteral).stringValue;
            return Glob(path);
          }).toList();
        } else {
          log.warning(
              'Tried to detect the type of Formatter configured for `FormatTool` but failed.');
        }
      }

      if (formatDevTool is FormatTool) {
        FormatTool typedFormatDevTool = formatDevTool;

        final formatter = formatterInvocation.getCascadeByProperty('formatter');
        if (excludesList.isNotEmpty) typedFormatDevTool.exclude = excludesList;
        if (formatter != null) {
          final formatterType = formatter.rightHandSide;
          if (formatterType is PrefixedIdentifier) {
            typedFormatDevTool.formatter =
                _detectFormatterForFormatTool(formatterType.identifier);
          } else {
            log.warning(
                'Tried to detect the type of Formatter configured for `FormatTool` but failed.');
          }
        }

        final formatterArgs =
            formatterInvocation.getCascadeByProperty('formatterArgs');

        if (formatterArgs != null) {
          final argList = formatterArgs.rightHandSide;
          if (argList is ListLiteral) {
            final stringArgs = argList.elements
                .whereType<StringLiteral>()
                .map((e) => e.stringValue)
                .toList();
            typedFormatDevTool.formatterArgs = stringArgs;

            if (stringArgs.length < argList.elements.length) {
              // TODO handle letting user know that args were removed
            }
          } else {
            log.warning(
                'Tried to detect the type of Formatter configured for `FormatTool` but failed.');
          }
        }
      } else if (formatDevTool is OverReactFormatTool) {
        OverReactFormatTool typedFormatDevTool = formatDevTool;
        final lineLengthAssignment =
            formatterInvocation.getCascadeByProperty('lineLength');
        if (excludesList.isNotEmpty) typedFormatDevTool.exclude = excludesList;
        if (lineLengthAssignment != null) {
          final lengthExpression = lineLengthAssignment.rightHandSide;
          if (lengthExpression is IntegerLiteral) {
            (formatDevTool as OverReactFormatTool).lineLength =
                lengthExpression.value;
          } else {
            log.warning(
                'Line-length auto-detection attempted, but the value for the FormatTool\'s line-length setting could not be parsed.');
          }
        }
      }
    }
  }
}

Formatter _detectFormatterForFormatTool(SimpleIdentifier formatterIdentifier) {
  Formatter formatter;

  switch (formatterIdentifier.name) {
    case 'dartfmt':
      formatter = Formatter.dartfmt;
      break;
    case 'dartStyle':
      formatter = Formatter.dartStyle;
      break;
    default:
      // TODO handle unknown formatter
      break;
  }

  return formatter;
}

DevTool _detectFormatter(AstNode formatterNode) {
  String detectedFormatterName;
  DevTool tool;

  if (formatterNode is MethodInvocation) {
    detectedFormatterName = formatterNode.methodName.name;
  } else if (formatterNode is CascadeExpression) {
    detectedFormatterName =
        formatterNode.target.toSource().replaceAll(RegExp('[()]'), '');
  }

  if (detectedFormatterName == 'FormatTool') {
    tool = FormatTool();
  } else if (detectedFormatterName == 'OverReactFormatTool') {
    tool = OverReactFormatTool();
  } else {
    // FIXME handle unknown formatter
  }

  return tool;
}

extension on CascadeExpression {
  AssignmentExpression getCascadeByProperty(String property) {
    return cascadeSections.whereType<AssignmentExpression>().firstWhere(
        (assignment) {
      final lhs = assignment.leftHandSide;
      return lhs is PropertyAccess && lhs.propertyName.name == property;
    }, orElse: () => null);
  }
}
