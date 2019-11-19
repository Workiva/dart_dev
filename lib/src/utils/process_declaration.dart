import 'dart:io';

class ProcessDeclaration {
  final List<String> args;
  final String executable;
  final ProcessStartMode mode;
  final String workingDirectory;

  ProcessDeclaration(this.executable, this.args,
      {this.mode, this.workingDirectory});
}
