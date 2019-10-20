// Copyright 2019 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// The logging utility in this file was originally modeled after:
// https://github.com/dart-lang/build/blob/0e79b63c6387adbb7e7f4c4f88d572b1242d24df/build_runner/lib/src/logging/std_io_logging.dart

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:io/ansi.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import 'parse_flag_from_args.dart';

// Ensures this message does not get overwritten by later logs.
const _logSuffix = '\n';

void attachLoggerToStdio(List<String> args) {
  final verbose = parseFlagFromArgs(args, 'verbose', abbr: 'v');
  Logger.root.level = verbose ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen(stdIOLogListener(verbose: verbose));
}

StringBuffer colorLog(LogRecord record, {bool verbose}) {
  verbose ??= false;

  AnsiCode color;
  if (record.level < Level.WARNING) {
    color = cyan;
  } else if (record.level < Level.SEVERE) {
    color = yellow;
  } else {
    color = red;
  }
  final level = color.wrap('[${record.level}]');
  final eraseLine = ansiOutputEnabled && !verbose ? '\x1b[2K\r' : '';
  final lines = <Object>[
    '$eraseLine$level ${_loggerName(record, verbose)}${record.message}'
  ];

  if (record.error != null) {
    lines.add(record.error);
  }

  if (record.stackTrace != null && verbose) {
    final trace = Trace.from(record.stackTrace).terse;
    lines.add(trace);
  }

  final message = StringBuffer(lines.join('\n'));

  // We always add an extra newline at the end of each message, so it
  // isn't multiline unless we see > 2 lines.
  final multiLine = convert.LineSplitter.split(message.toString()).length > 2;

  if (record.level > Level.INFO || !ansiOutputEnabled || multiLine || verbose) {
    if (!lines.last.toString().endsWith('\n')) {
      // Add a newline to the output so the last line isn't written over.
      message.writeln('');
    }
  }
  return message;
}

/// Returns a human readable string for a duration.
///
/// Handles durations that span up to hours - this will not be a good fit for
/// durations that are longer than days.
///
/// Always attempts 2 'levels' of precision. Will show hours/minutes,
/// minutes/seconds, seconds/tenths of a second, or milliseconds depending on
/// the largest level that needs to be displayed.
String humanReadable(Duration duration) {
  if (duration < const Duration(seconds: 1)) {
    return '${duration.inMilliseconds}ms';
  }
  if (duration < const Duration(minutes: 1)) {
    return '${(duration.inMilliseconds / 1000.0).toStringAsFixed(1)}s';
  }
  if (duration < const Duration(hours: 1)) {
    final minutes = duration.inMinutes;
    final remaining = duration - Duration(minutes: minutes);
    return '${minutes}m ${remaining.inSeconds}s';
  }
  final hours = duration.inHours;
  final remaining = duration - Duration(hours: hours);
  return '${hours}h ${remaining.inMinutes}m';
}

void logSubprocessHeader(Logger logger, String command, {Level level}) {
  level ??= Level.INFO;
  logger.log(
      level,
      'Running subprocess:\n' +
          magenta.wrap(command) +
          '\n' +
          '-' * (io.stdout.hasTerminal ? io.stdout.terminalColumns : 79) +
          '\n');
}

/// Logs an asynchronous [action] with [description] before and after.
///
/// Returns a future that completes after the action and logging finishes.
Future<T> logTimedAsync<T>(
  Logger logger,
  String description,
  Future<T> action(), {
  Level level,
}) async {
  level ??= Level.INFO;
  final watch = Stopwatch()..start();
  logger.log(level, '$description...');
  final result = await action();
  watch.stop();
  final time = '${humanReadable(watch.elapsed)}$_logSuffix';
  logger.log(level, '$description completed, took $time');
  return result;
}

/// Logs a synchronous [action] with [description] before and after.
///
/// Returns a future that completes after the action and logging finishes.
T logTimedSync<T>(
  Logger logger,
  String description,
  T action(), {
  Level level = Level.INFO,
}) {
  final watch = Stopwatch()..start();
  logger.log(level, '$description...');
  final result = action();
  watch.stop();
  final time = '${humanReadable(watch.elapsed)}$_logSuffix';
  logger.log(level, '$description completed, took $time');
  return result;
}

void Function(LogRecord) stdIOLogListener({bool verbose}) =>
    (record) => io.stdout.write(colorLog(record, verbose: verbose));

String _loggerName(LogRecord record, bool verbose) {
  final maybeSplit = record.level >= Level.WARNING ? '\n' : ' ';
  return verbose ? '${record.loggerName}:$maybeSplit' : '';
}
