import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_dev/src/tools/over_react_format_tool.dart';
import 'package:glob/glob.dart';

import '../../dart_dev.dart';
import 'logging.dart';

enum KnownFormatTools { FormatTool, OverReactFormatTool }

/// Visits a `dart_dev/config.dart` file and searches for a custom formatter.
///
/// When a custom formatter is found, this will look for possible configuration options
/// and reconstruct them on a new formatter instance.
///
/// NOTE: Because the visitor doesn't have access to the scope of the configuration
/// being parsed, most values need to be a literal type (ListLiteral, StringLiteral, IntegerLiteral)
/// to be reconstructed.
///
/// Expects the configuration to be in the format of:
/// ```dart
/// final config = {
///   'format': OverReactFormatTool()
///     ..lineLength = 120,
/// };
/// ```
class FormatToolBuilder extends GeneralizingAstVisitor<void> {
  DevTool formatDevTool;

  bool failedToDetectAKnownFormatter = false;

  @override
  visitMapLiteralEntry(MapLiteralEntry node) {
    super.visitMapLiteralEntry(node);

    String mapEntryKey = node.key.toSource().replaceAll("'", "");

    if (mapEntryKey != 'format') return;

    final formatterInvocation = node.value;
    formatDevTool = detectFormatter(node.value);

    if (formatDevTool == null) {
      failedToDetectAKnownFormatter = true;
      return;
    }

    if (formatterInvocation is CascadeExpression) {
      List<Glob> reconstructedExcludesList = [];

      final excludeExpression =
          formatterInvocation.getCascadeByProperty('exclude');
      if (excludeExpression != null) {
        final detectedExcludesList = excludeExpression.rightHandSide;
        if (detectedExcludesList is ListLiteral) {
          reconstructedExcludesList = detectedExcludesList.elements
              .whereType<MethodInvocation>()
              .where((e) {
            return e.argumentList.arguments.length == 1 &&
                e.argumentList.arguments.first is StringLiteral;
          }).map((e) {
            final path =
                (e.argumentList.arguments.first as StringLiteral).stringValue;
            return Glob(path);
          }).toList();

          if (reconstructedExcludesList.length <
              detectedExcludesList.elements.length) {
            logWarningMessageFor(
                KnownErrorOutcome.failedToReconstructAllExcludes);
          }
        } else {
          logWarningMessageFor(KnownErrorOutcome.failedToParseExcludes);
        }
      }

      if (formatDevTool is FormatTool) {
        FormatTool typedFormatDevTool = formatDevTool;

        final formatter = formatterInvocation.getCascadeByProperty('formatter');
        if (reconstructedExcludesList.isNotEmpty) {
          typedFormatDevTool.exclude = reconstructedExcludesList;
        }
        if (formatter != null) {
          final formatterType = formatter.rightHandSide;
          if (formatterType is PrefixedIdentifier) {
            typedFormatDevTool.formatter =
                detectFormatterForFormatTool(formatterType.identifier);
          } else {
            logWarningMessageFor(KnownErrorOutcome.failedToParseFormatter);
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
              logWarningMessageFor(
                  KnownErrorOutcome.failedToReconstructFormatterArgs);
            }
          } else {
            logWarningMessageFor(KnownErrorOutcome.failedToParseFormatterArgs);
          }
        }
      } else if (formatDevTool is OverReactFormatTool) {
        OverReactFormatTool typedFormatDevTool = formatDevTool;
        final lineLengthAssignment =
            formatterInvocation.getCascadeByProperty('lineLength');
        if (reconstructedExcludesList.isNotEmpty) {
          typedFormatDevTool.exclude = reconstructedExcludesList;
        }
        if (lineLengthAssignment != null) {
          final lengthExpression = lineLengthAssignment.rightHandSide;
          if (lengthExpression is IntegerLiteral) {
            (formatDevTool as OverReactFormatTool).lineLength =
                lengthExpression.value;
          } else {
            logWarningMessageFor(KnownErrorOutcome.failedToParseLineLength);
          }
        }
      }
    }
  }
}

enum KnownErrorOutcome {
  failedToReconstructAllExcludes,
  failedToParseExcludes,
  failedToParseFormatter,
  failedToReconstructFormatterArgs,
  failedToParseFormatterArgs,
  failedToParseLineLength,
}

void logWarningMessageFor(KnownErrorOutcome outcome) {
  String errorMessage;

  switch (outcome) {
    case KnownErrorOutcome.failedToReconstructAllExcludes:
      errorMessage = '''Failed to reconstruct all items in the excludes list.

This is likely due to a `Glob` having more than one parameter (expected only one) or
the path parameter not being a StringLiteral.
''';
      break;
    case KnownErrorOutcome.failedToParseExcludes:
      errorMessage = '''Failed to parse the excludes list.

This is likely because the list is not a ListLiteral.
''';
      break;
    case KnownErrorOutcome.failedToParseFormatter:
      errorMessage = '''Failed to parse the formatter configuration.

This is likely because the assigned value is not in the form `Formatter.<formatter_option>`.
''';
      break;
    case KnownErrorOutcome.failedToReconstructFormatterArgs:
      errorMessage =
          '''Failed to reconstruct all items in the formatterArgs list.

This is likely because the list contained types that were not StringLiterals.
''';
      break;
    case KnownErrorOutcome.failedToParseFormatterArgs:
      errorMessage = '''Failed to parse the formatterArgs list.

This is likely because the list is not a ListLiteral.
''';
      break;
    case KnownErrorOutcome.failedToParseLineLength:
      errorMessage = '''Failed to parse the line-length configuration.

This is likely because assignment does not use an IntegerLiteral.
''';
      break;
  }

  log.warning(errorMessage);
}

Formatter detectFormatterForFormatTool(SimpleIdentifier formatterIdentifier) {
  Formatter formatter;

  switch (formatterIdentifier.name) {
    case 'dartfmt':
      formatter = Formatter.dartfmt;
      break;
    case 'dartStyle':
      formatter = Formatter.dartStyle;
      break;
    default:
      break;
  }

  return formatter;
}

DevTool detectFormatter(AstNode formatterNode) {
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
