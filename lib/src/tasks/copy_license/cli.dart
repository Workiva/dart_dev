library dart_dev.src.tasks.copy_license.cli;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:dart_dev/src/tasks/copy_license/api.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

class CopyLicenseCli extends TaskCli {
  final ArgParser argParser = new ArgParser();

  final String command = 'copy-license';

  Future<CliResult> run(ArgResults parsedArgs) async {
    List<String> directories = config.copyLicense.directories;
    String licensePath = config.copyLicense.licensePath;

    if (!(new File(licensePath)).existsSync()) return new CliResult.fail(
        'License file "$licensePath" does not exist.');

    CopyLicenseTask task =
        copyLicense(directories: directories, licensePath: licensePath);
    await task.done;
    if (task.successful) {
      int numFiles = task.affectedFiles.length;
      String fileSummary = '\n  ${task.affectedFiles.join('\n  ')}';
      String result = numFiles == 0
          ? 'License already exists on all files.'
          : 'License successfully applied to $numFiles files:$fileSummary';
      return new CliResult.success(result);
    } else {
      return new CliResult.fail('License application failed.');
    }
  }
}
