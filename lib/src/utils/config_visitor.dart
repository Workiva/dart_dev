import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'logging.dart';

/// Visits a `dart_dev/config.dart` file and searches for a line length.
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
class ConfigVisitor extends GeneralizingAstVisitor {
  int lineLength;
  bool usesCustomFormatter = false;
  bool usesOverReactFormat = false;

  ConfigVisitor();

  @override
  visitMapLiteralEntry(MapLiteralEntry node) {
    super.visitMapLiteralEntry(node);

    SimpleStringLiteral formatKey = node.key.childEntities.firstWhere((e) {
      if (e is SimpleStringLiteral) {
        if (e.value == 'format') {
          return true;
        }
      }

      return false;
    }, orElse: () => null);

    if (formatKey != null) {
      if (node.value.runtimeType.toString() != 'FormatTool') {
        usesCustomFormatter = true;

        if (node.value.runtimeType.toString() == 'OverReactFormatTool') {
          usesOverReactFormat = true;
        }
      }
    }
  }

  @override
  visitCascadeExpression(CascadeExpression node) {
    final lineLengthAssignment = node.cascadeSections
        .whereType<AssignmentExpression>()
        .firstWhere((assignment) {
      final lhs = assignment.leftHandSide;
      return lhs is PropertyAccess && lhs.propertyName.name == 'lineLength';
    }, orElse: () => null);

    if (lineLengthAssignment != null) {
      final lengthExpression = lineLengthAssignment.rightHandSide;
      if (lengthExpression is IntegerLiteral) {
        lineLength = lengthExpression.value;
      } else {
        log.warning('Line-length auto-detection attempted, but the value for the FormatTool\'s line-length setting could not be parsed.');
      }
    }

    return super.visitCascadeExpression(node);
  }
}

/// A wrapper around a line-length value.
///
/// This is used to allow [ConfigVisitor] to mutate a reference that is declared
/// (and returned by) [getLineLength].
class _LineLength {
  int lineLength;
}
