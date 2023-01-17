/// Returns the Dart version comment contained in a given [source] file,
/// or `null` if one does not exist.
///
/// Uses regex over the analyzer for performance.
String? getDartVersionComment(String source) =>
    RegExp(r'^//\s*@dart\s*=.+$', multiLine: true).firstMatch(source)?.group(0);
