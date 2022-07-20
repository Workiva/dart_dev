import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'import.dart';

/// A visitor which collects all imports.
///
/// Imports are returned in the order they appear in a file when passed to `CompilationUnit.accept`.
class ImportCollector extends SimpleAstVisitor<List<Import>> {
  final List<Import> _imports = [];

  @override
  List<Import> visitImportDirective(ImportDirective node) {
    _imports.add(Import(node));
    return null;
  }

  @override
  List<Import> visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return _imports;
  }
}
