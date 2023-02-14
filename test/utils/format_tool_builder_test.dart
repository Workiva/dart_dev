@TestOn('vm')

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/tools/over_react_format_tool.dart';
import 'package:dart_dev/src/utils/format_tool_builder.dart';
import 'package:test/test.dart';

void main() {
  group('FormatToolBuilder', () {
    group('detects an OverReactFormatTool correctly', () {
      test('when the tool is a MethodInvocation', () {
        final visitor = FormatToolBuilder();

        parseString(content: orfNoCascadeSrc).unit.accept(visitor);

        expect(visitor.formatDevTool, isNotNull);
        expect(visitor.formatDevTool, isA<OverReactFormatTool>());
      });

      group('when the tool is a CascadeExpression', () {
        test('detects line-length', () {
          final visitor = FormatToolBuilder();

          parseString(content: orfCascadeSrc).unit.accept(visitor);

          expect(visitor.formatDevTool, isNotNull);
          expect(visitor.formatDevTool, isA<OverReactFormatTool>());
          expect(
              (visitor.formatDevTool as OverReactFormatTool).lineLength, 120);
        });
      });
    });

    group('detects a FormatTool correctly', () {
      test('when the tool is a MethodInvocation', () {
        final visitor = FormatToolBuilder();

        parseString(content: formatToolNoCascadeSrc).unit.accept(visitor);

        expect(visitor.formatDevTool, isNotNull);
        expect(visitor.formatDevTool, isA<FormatTool>());
      });

      group('when the tool is a CascadeExpression', () {
        group('detects formatter correctly for:', () {
          test('darfmt', () {
            final visitor = FormatToolBuilder();

            parseString(content: formatToolCascadeSrc()).unit.accept(visitor);

            expect(visitor.formatDevTool, isNotNull);
            expect(visitor.formatDevTool, isA<FormatTool>());
            expect((visitor.formatDevTool as FormatTool).formatter,
                Formatter.dartfmt);
          });

          test('dartFormat', () {
            final visitor = FormatToolBuilder();

            parseString(content: formatToolCascadeSrc(formatter: 'dartFormat'))
                .unit
                .accept(visitor);

            expect(visitor.formatDevTool, isNotNull);
            expect(visitor.formatDevTool, isA<FormatTool>());
            expect((visitor.formatDevTool as FormatTool).formatter,
                Formatter.dartFormat);
          });

          test('dartStyle', () {
            final visitor = FormatToolBuilder();

            parseString(content: formatToolCascadeSrc(formatter: 'dartStyle'))
                .unit
                .accept(visitor);

            expect(visitor.formatDevTool, isNotNull);
            expect(visitor.formatDevTool, isA<FormatTool>());
            expect((visitor.formatDevTool as FormatTool).formatter,
                Formatter.dartStyle);
          });
        });

        test('detects formatterArgs', () {
          final visitor = FormatToolBuilder();

          parseString(content: formatToolCascadeSrc()).unit.accept(visitor);

          expect(visitor.formatDevTool, isNotNull);
          expect(visitor.formatDevTool, isA<FormatTool>());
          expect((visitor.formatDevTool as FormatTool).formatterArgs,
              orderedEquals(['-l', '120']));
        });
      });
    });

    test(
        'sets the failedToDetectAKnownFormatter flag when an unknown FormatTool is being used',
        () {
      final visitor = FormatToolBuilder();

      parseString(content: unknownFormatterTool).unit.accept(visitor);

      expect(visitor.formatDevTool, isNull);
      expect(visitor.failedToDetectAKnownFormatter, isTrue);
    });
  });
}

const orfNoCascadeSrc = '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...coreConfig,
  'format': OverReactFormatTool(),
};
''';

const orfCascadeSrc = '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...coreConfig,
  'format': OverReactFormatTool()
    ..lineLength = 120,
};
''';

const formatToolNoCascadeSrc = '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...coreConfig,
  'format': FormatTool(),
};
''';

String formatToolCascadeSrc({String formatter = 'dartfmt'}) =>
    '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...coreConfig,
  'format': FormatTool()
    ..formatter = Formatter.$formatter
    ..formatterArgs = ['-l', '120'],
};
''';

const unknownFormatterTool = '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';

final config = {
  ...coreConfig,
  'format': UnknownTool()
    ..formatter = Formatter.dartfmt
    ..formatterArgs = ['-l', '120'],
};
''';
