library dart_dev.src.task_process;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TaskProcess {
  Completer _donec = new Completer();
  Completer _errc = new Completer();
  Completer _outc = new Completer();
  Completer<int> _procExitCode = new Completer();

  StreamController<String> _stdout = new StreamController();
  StreamController<String> _stderr = new StreamController();

  TaskProcess(String executable, List<String> arguments) {
    Process.start(executable, arguments).then((process) {
      process.stdout
          .transform(UTF8.decoder)
          .transform(new LineSplitter())
          .listen(_stdout.add, onDone: _outc.complete);
      process.stderr
          .transform(UTF8.decoder)
          .transform(new LineSplitter())
          .listen(_stderr.add, onDone: _errc.complete);
      _outc.future.then((_) => _stdout.close());
      _errc.future.then((_) => _stderr.close());
      process.exitCode.then(_procExitCode.complete);
      Future.wait([_outc.future, _errc.future, process.exitCode])
          .then((_) => _donec.complete());
    });
  }

  Future get done => _donec.future;

  Future<int> get exitCode => _procExitCode.future;

  Stream<String> get stderr => _stderr.stream;
  Stream<String> get stdout => _stdout.stream;
}
