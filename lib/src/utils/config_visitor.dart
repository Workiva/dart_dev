import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'logging.dart';

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
class ConfigVisitor extends GeneralizingAstVisitor<void> {
  int lineLength;
  bool usesCustomFormatter = false;
  bool usesOverReactFormat = false;

  ConfigVisitor();

  @override
  visitMapLiteralEntry(MapLiteralEntry node) {
    super.visitMapLiteralEntry(node);

    String mapEntryKey = node.key.toSource().replaceAll("'", "");

    void detectFormatter(String methodName) {
      if (methodName != 'FormatTool') {
        this.usesCustomFormatter = true;

        if (methodName == 'OverReactFormatTool') {
          this.usesOverReactFormat = true;
        }
      }
    }

    if (mapEntryKey == "format") {
      final mapEntryValue = node.value;
      if (mapEntryValue is MethodInvocation) {
        detectFormatter(mapEntryValue.methodName.name);
      } else if (mapEntryValue is CascadeExpression) {
        detectFormatter(
            mapEntryValue.target.toSource().replaceAll(RegExp('[()]'), ''));

        final lineLengthAssignment = mapEntryValue.cascadeSections
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
            log.warning(
                'Line-length auto-detection attempted, but the value for the FormatTool\'s line-length setting could not be parsed.');
          }
        }
      }
    }
  }
}
