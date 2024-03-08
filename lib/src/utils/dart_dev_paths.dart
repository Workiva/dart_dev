import 'package:path/path.dart' as p;

/// A collection of paths to files and directories constructed to be compatible
/// with a given [p.Context].
class DartDevPaths {
  final p.Context _context;

  DartDevPaths({p.Context? context}) : _context = context ?? p.context;

  String cache([String? subPath]) => _context.normalize(
      _context.joinAll([..._cacheParts, if (subPath != null) subPath]));

  String get _cacheForDart => p.url.joinAll(_cacheParts);

  final List<String> _cacheParts = ['.dart_tool', 'dart_dev'];

  String get config => _context.joinAll(_configParts);

  String get configForDart => p.url.joinAll(_configParts);

  final List<String> _configParts = ['tool', 'dart_dev', 'config.dart'];

  String get configFromRunScriptForDart => p.url.relative(
        p.url.absolute(configForDart),
        from: p.url.absolute(_cacheForDart),
      );

  String get packageConfig => _context.join('.dart_tool', 'package_config.json');

  String get legacyConfig => _context.join('tool', 'dev.dart');

  String get runScript => cache('run.dart');

  String get runExecutable => cache('run');

  String get runExecutableDigest => cache('run.digest');
}
