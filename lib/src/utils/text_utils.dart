// Copyright 2015 Workiva Inc.
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

import 'package:ansicolor/ansicolor.dart';

final AnsiPen _bold = new AnsiPen()..magenta(bold: true);
final AnsiPen _blue = new AnsiPen()..cyan();
final AnsiPen _green = new AnsiPen()..green();
final AnsiPen _red = new AnsiPen()..red();
final AnsiPen _yellow = new AnsiPen()..yellow();

abstract class BaseReporter {
  int _currentIndent = 0;
  AnsiPen _pen;
  StringSink _sink;
  final bool _useColor;

  BaseReporter(StringSink sink, {bool useColor: true})
      : _sink = sink,
        _useColor = useColor;

  void dedent() {
    if (_currentIndent == 0) {
      throw new StateError('Cannot dedent any further.');
    }
    _currentIndent--;
  }

  void error([Object obj = '']) {
    writeln(_color('$obj', _red));
  }

  void h1([Object obj = '']) {
    final text = obj.toString();
    writeln(_color(':: $text\n${'-' * (text.length + 3)}', _blue));
  }

  void h2([Object obj = '']) {
    writeln(_color('===== $obj', _blue));
  }

  void important([Object obj = '']) {
    writeln(_color('$obj', _bold));
  }

  void indent() {
    _currentIndent++;
  }

  void success([Object obj = '']) {
    writeln(_color(obj, _green));
  }

  void warning([Object obj = '']) {
    writeln(_color(obj, _yellow));
  }

  void writeln([Object obj = '']) {
    final lines = obj.toString().split('\n');
    for (final line in lines) {
      _sink.write(' ' * _currentIndent * 2);
      _sink.writeln(_pen != null && _useColor ? _pen(line) : line);
    }
  }

  String _color(String text, AnsiPen pen) {
    return _useColor ? pen(text) : text;
  }
}

class Reporter extends BaseReporter {
  final StringSink _sink;

  Reporter(StringSink sink, {bool useColor: true})
      : _sink = sink,
        super(sink, useColor: useColor);
}

class BufferedReporter extends BaseReporter {
  BufferedReporter({bool useColor: true})
      : super(new StringBuffer(), useColor: useColor);

  @override
  String toString() => _sink.toString();
}
