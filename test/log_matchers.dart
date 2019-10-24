// These matchers are borrowed from the build package:
// https://github.com/dart-lang/build/blob/a337a908a25e4d1bd06e898f40c3c013a7ec04e3/build_test/lib/src/record_logs.dart
library dart_dev.test.log_matchers;

import 'package:logging/logging.dart';
import 'package:matcher/matcher.dart';

/// Matches [LogRecord] of any level whose message is [messageOrMatcher].
///
/// ```dart
/// anyLogOf('Hello World)';     // Exactly match 'Hello World'.
/// anyLogOf(contains('ERROR')); // Contains the sub-string 'ERROR'.
/// ```
Matcher anyLogOf(dynamic messageOrMatcher) =>
    _LogRecordMatcher(anything, messageOrMatcher);

/// Matches [LogRecord] of [Level.FINE] where message is [messageOrMatcher].
Matcher fineLogOf(dynamic messageOrMatcher) =>
    _LogRecordMatcher(Level.FINE, messageOrMatcher);

/// Matches [LogRecord] of [Level.INFO] where message is [messageOrMatcher].
Matcher infoLogOf(dynamic messageOrMatcher) =>
    _LogRecordMatcher(Level.INFO, messageOrMatcher);

/// Matches [LogRecord] of [Level.WARNING] where message is [messageOrMatcher].
Matcher warningLogOf(dynamic messageOrMatcher) =>
    _LogRecordMatcher(Level.WARNING, messageOrMatcher);

/// Matches [LogRecord] of [Level.SEVERE] where message is [messageOrMatcher].
Matcher severeLogOf(dynamic messageOrMatcher) =>
    _LogRecordMatcher(Level.SEVERE, messageOrMatcher);

class _LogRecordMatcher extends Matcher {
  final Matcher _level;
  final Matcher _message;

  factory _LogRecordMatcher(dynamic levelOr, dynamic messageOr) =>
      _LogRecordMatcher._(levelOr is Matcher ? levelOr : equals(levelOr),
          messageOr is Matcher ? messageOr : equals(messageOr));

  _LogRecordMatcher._(this._level, this._message);

  @override
  Description describe(Description description) {
    description.add('level: ');
    _level.describe(description);
    description.add(', message: ');
    _message.describe(description);
    return description;
  }

  @override
  Description describeMismatch(covariant LogRecord item,
      Description description, Map<dynamic, dynamic> _, bool __) {
    if (!_level.matches(item.level, {})) {
      _level.describeMismatch(item.level, description, {}, false);
    }
    if (!_message.matches(item.message, {})) {
      _message.describeMismatch(item.message, description, {}, false);
    }
    return description;
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> _) =>
      item is LogRecord &&
      _level.matches(item.level, {}) &&
      _message.matches(item.message, {});
}
