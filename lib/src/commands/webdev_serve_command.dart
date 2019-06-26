import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:logging/logging.dart';

import '../utils/ensure_process_exit.dart';
import '../utils/has_any_positional_args_before_separator.dart';
import '../utils/package_is_globally_activated.dart';

final _log = Logger('AnalyzeTool');

// TODO: Make this a `WebdevCommand` with subcommands for `build` and `serve`.
class WebdevServeCommand extends Command<int> {
  final WebdevServeConfig config;

  WebdevServeCommand([WebdevServeConfig config])
      : config = config ?? WebdevServeConfig();

  @override
  String get name => config.commandName ?? 'webdev_serve';

  @override
  String get description =>
      config.description ??
      'Run a local web development server and a file system watcher that rebuilds on changes.';

  @override
  bool get hidden => config.hidden ?? false;

  @override
  String get invocation =>
      '${super.invocation.replaceFirst('[arguments]', '[dart_dev arguments]')} '
      '[-- [webdev serve arguments]]';

  @override
  String get usageFooter => '\n'
      'Run "webdev serve -h" to see the available webdev arguments.\n'
      'You can use any of them with "dart_dev $name" by passing them after a '
      '"--" separator.';

  @override
  Future<int> run() async {
    assertNoPositionalArgsBeforeSeparator(name, argResults, usageException);
    if (!packageIsGloballyActivated('webdev')) {
      _log.severe(red.wrap('Could not run webdev serve.\n') +
          yellow.wrap('You must have `webdev` globally activated:\n'
              '    pub global activate webdev'));
    }
    final args = buildWebdevServeArgs(config, argResults);
    _log.info('Running: pub ${args.join(' ')}');
    final process =
        await Process.start('pub', args, mode: ProcessStartMode.inheritStdio);
    ensureProcessExit(process, log: _log);
    return process.exitCode;
  }

  static void assertNoPositionalArgsBeforeSeparator(
    String name,
    ArgResults argResults,
    void usageException(String message),
  ) {
    if (hasAnyPositionalArgsBeforeSeparator(argResults)) {
      usageException('The "$name" command does not support positional args '
          'before the "--" separator.\n'
          'Args for webdev serve should be passed in after a "--" separator.');
    }
  }

  static Iterable<String> buildWebdevServeArgs(
          WebdevServeConfig config, ArgResults argResults) =>
      [
        'global',
        'run',
        'webdev',
        'serve',

        // Pass through the configured webdev serve args (this may be empty).
        ...config.webdevServeArgs ?? [],

        // Pass through the rest of the args (this may be empty).
        ...argResults.rest,
      ];
}

class WebdevServeConfig {
  WebdevServeConfig({
    this.commandName,
    this.description,
    this.hidden,
    this.webdevServeArgs,
  });

  final String commandName;

  final String description;

  final bool hidden;

  final List<String> webdevServeArgs;

  WebdevServeConfig merge(WebdevServeConfig other) => WebdevServeConfig(
        commandName: other?.commandName ?? commandName,
        description: other?.description ?? description,
        hidden: other?.hidden ?? hidden,
        webdevServeArgs: other?.webdevServeArgs ?? webdevServeArgs,
      );
}
