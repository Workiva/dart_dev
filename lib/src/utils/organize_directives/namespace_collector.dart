import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// A visitor which collects all imports and exports.
///
/// Imports and exports are returned in the order they appear in a file when
/// passed to `CompilationUnit.accept`.
class NamespaceCollector extends SimpleAstVisitor<List<NamespaceDirective>> {
  List<NamespaceDirective> _namespaces = [];

  @override
  List<NamespaceDirective> visitExportDirective(ExportDirective node) {
    _namespaces.add(node);
    return null;
  }

  @override
  List<NamespaceDirective> visitImportDirective(ImportDirective node) {
    _namespaces.add(node);
    return null;
  }

  @override
  List<NamespaceDirective> visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return _namespaces;
  }
}
