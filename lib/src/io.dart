library dart_dev.src.io;

import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';

Reporter reporter = new Reporter();

final AnsiPen _blue = new AnsiPen()..cyan();
final AnsiPen _green = new AnsiPen()..green();
final AnsiPen _red = new AnsiPen()..red();
final AnsiPen _yellow = new AnsiPen()..yellow();

String parseExecutableFromCommand(String command) {
  return command.split(' ').first;
}

List<String> parseArgsFromCommand(String command) {
  var parts = command.split(' ');
  if (parts.length <= 1) return [];
  return parts.getRange(1, parts.length).toList();
}

class Reporter {
  bool color = true;
  bool quiet = false;

  Reporter({bool this.color, bool this.quiet});

  String colorBlue(String message) => _color(_blue, message);

  String colorGreen(String message) => _color(_green, message);

  String colorRed(String message) => _color(_red, message);

  String colorYellow(String message) => _color(_yellow, message);

  void log(String message, {bool shout: false}) {
    _log(stdout, message, shout: shout);
  }

  void logGroup(String title,
      {String output,
      Stream<String> outputStream,
      Stream<String> errorStream}) {
    log(colorBlue('\n::: $title'));
    if (output != null) {
      log('${output.split('\n').join('\n    ')}');
      return;
    }

    if (outputStream != null) {
      outputStream.listen((line) {
        log('    $line');
      });
    }
    if (errorStream != null) {
      errorStream.listen((line) {
        warning('    $line');
      });
    }
  }

  void error(String message, {bool shout: false}) {
    _log(stderr, colorRed(message), shout: shout);
  }

  void success(String message, {bool shout: false}) {
    log(colorGreen(message), shout: shout);
  }

  void warning(String message, {bool shout: false}) {
    _log(stderr, colorYellow(message), shout: shout);
  }

  String _color(AnsiPen pen, String message) => color ? pen(message) : message;

  void _log(IOSink sink, String message, {bool shout: false}) {
    if (quiet && !shout) return;
    sink.writeln(message);
  }
}
