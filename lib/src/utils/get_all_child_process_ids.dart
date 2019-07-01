import 'dart:convert';
import 'dart:io';

Future<List<int>> getAllChildProcessIds({int parentPid}) async {
  parentPid ??= pid;
  final pgrepProcess = await Process.start('pgrep', ['-P', '$parentPid'],
      mode: ProcessStartMode.detachedWithStdio);
  final childPids = (await pgrepProcess.stdout
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .toList())
      .map(int.parse);
  return [
    ...childPids,
    for (final cpid in childPids)
      ...await getAllChildProcessIds(parentPid: cpid),
  ];
}
