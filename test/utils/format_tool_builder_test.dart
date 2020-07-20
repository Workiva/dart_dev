@TestOn('vm')

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_dev/dart_dev.dart';
import 'package:dart_dev/src/tools/over_react_format_tool.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import 'package:dart_dev/src/utils/format_tool_builder.dart';

void main() {
  group('FormatToolBuilder', () {
    group('detects an OverReactFormatTool correctly', () {
      test('when the tool is a MethodInvocation', () {
        final visitor = FormatToolBuilder();

        parseString(content: orf_noCascadeSrc).unit.accept(visitor);

        expect(visitor.formatDevTool, isNotNull);
        expect(visitor.formatDevTool, isA<OverReactFormatTool>());
      });

      group('when the tool is a CascadeExpression', () {
        test('detects line-length', () {
          final visitor = FormatToolBuilder();

          parseString(content: orf_cascadeSrc).unit.accept(visitor);

          expect(visitor.formatDevTool, isNotNull);
          expect(visitor.formatDevTool, isA<OverReactFormatTool>());
          expect(
              (visitor.formatDevTool as OverReactFormatTool).lineLength, 120);
        });

        test('detects excludes', () {
          final visitor = FormatToolBuilder();

          parseString(content: orf_cascadeSrc).unit.accept(visitor);

          expect(visitor.formatDevTool, isNotNull);
          expect(visitor.formatDevTool, isA<OverReactFormatTool>());

          OverReactFormatTool typedTool = visitor.formatDevTool;

          final expectedGlobs = [
            Glob('app/**'),
            Glob('test/unit/generated_runner_test.dart')
          ];

          // A hacky variant of ordered equals, necessary because the two lists are not equal
          // due to the Glob instances being different (even if they're provided the same path).
          for (var i = 1; i < typedTool.exclude.length; i++) {
            expect(typedTool.exclude[i].pattern, expectedGlobs[i].pattern);
          }
        });
      });
    });

    group('detects a FormatTool correctly', () {
      test('when the tool is a MethodInvocation', () {
        final visitor = FormatToolBuilder();

        parseString(content: formatTool_noCascadeSrc).unit.accept(visitor);

        expect(visitor.formatDevTool, isNotNull);
        expect(visitor.formatDevTool, isA<FormatTool>());
      });

      group('when the tool is a CascadeExpression', () {
        group('detects formatter correctly for:', () {
          test('darfmt', () {
            final visitor = FormatToolBuilder();

            parseString(content: formatTool_cascadeSrc()).unit.accept(visitor);

            expect(visitor.formatDevTool, isNotNull);
            expect(visitor.formatDevTool, isA<FormatTool>());
            expect((visitor.formatDevTool as FormatTool).formatter,
                Formatter.dartfmt);
          });

          test('dartStyle', () {
            final visitor = FormatToolBuilder();

            parseString(content: formatTool_cascadeSrc(formatter: 'dartStyle'))
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

          parseString(content: formatTool_cascadeSrc()).unit.accept(visitor);

          expect(visitor.formatDevTool, isNotNull);
          expect(visitor.formatDevTool, isA<FormatTool>());
          expect((visitor.formatDevTool as FormatTool).formatterArgs,
              orderedEquals(['-l', '120']));
        });

        test('detects excludes', () {
          final visitor = FormatToolBuilder();

          parseString(content: formatTool_cascadeSrc()).unit.accept(visitor);

          expect(visitor.formatDevTool, isNotNull);
          expect(visitor.formatDevTool, isA<FormatTool>());

          FormatTool typedTool = visitor.formatDevTool;

          final expectedGlobs = [
            Glob('app/**'),
            Glob('test/unit/generated_runner_test.dart')
          ];

          // A hacky variant of ordered equals, necessary because the two lists are not equal
          // due to the Glob instances being different.
          for (var i = 1; i < typedTool.exclude.length; i++) {
            expect(typedTool.exclude[i].pattern, expectedGlobs[i].pattern);
          }
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

const orf_noCascadeSrc = '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';
import 'package:over_react_format/dart_dev_tool.dart';

final config = {
  ...coreConfig,
  'format': OverReactFormatTool(),
};
''';

const orf_cascadeSrc = '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';
import 'package:over_react_format/dart_dev_tool.dart';

final config = {
  ...coreConfig,
  'format': OverReactFormatTool()
    ..lineLength = 120
    ..exclude = [Glob('app/**'), Glob('test/unit/generated_runner_test.dart')],
};
''';

const formatTool_noCascadeSrc = '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';
import 'package:over_react_format/dart_dev_tool.dart';

final config = {
  ...coreConfig,
  'format': FormatTool(),
};
''';

String formatTool_cascadeSrc({String formatter = 'dartfmt'}) =>
    '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';
import 'package:over_react_format/dart_dev_tool.dart';

final config = {
  ...coreConfig,
  'format': FormatTool()
    ..formatter = Formatter.$formatter
    ..formatterArgs = ['-l', '120']
    ..exclude = [Glob('app/**'), Glob('test/unit/generated_runner_test.dart')],
};
''';

const unknownFormatterTool = '''import 'package:dart_dev/dart_dev.dart';
import 'package:glob/glob.dart';
import 'package:over_react_format/dart_dev_tool.dart';

final config = {
  ...coreConfig,
  'format': UnknownTool()
    ..formatter = Formatter.dartfmt
    ..formatterArgs = ['-l', '120']
    ..exclude = [Glob('test/unit/generated_runner_test.dart')],
};
''';
