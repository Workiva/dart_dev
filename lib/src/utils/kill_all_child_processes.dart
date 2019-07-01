import 'dart:io';

import 'get_all_child_process_ids.dart';

Future<bool> killAllChildProcesses(
    {int parentPid, ProcessSignal signal}) async {
  signal ??= ProcessSignal.sigterm;
  final childPids = await getAllChildProcessIds(parentPid: parentPid);
  return childPids.map((id) => Process.killPid(id)).every((r) => r == true);
}
