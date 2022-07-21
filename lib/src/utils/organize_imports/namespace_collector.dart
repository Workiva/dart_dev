import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'namespace.dart';

/// A visitor which collects all imports and exports.
///
/// Imports and exports are returned in the order they appear in a file when
/// passed to `CompilationUnit.accept`.
class NamespaceCollector extends SimpleAstVisitor<List<Namespace>> {
  List<Namespace> _namespaces = [];

  @override
  List<Namespace> visitExportDirective(ExportDirective node) {
    _namespaces.add(Namespace(node));
    return null;
  }

  @override
  List<Namespace> visitImportDirective(ImportDirective node) {
    _namespaces.add(Namespace(node));
    return null;
  }

  @override
  List<Namespace> visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return _namespaces;
  }
}
