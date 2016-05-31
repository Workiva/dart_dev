void main(List<String> arguments) {
  String output;
  if (arguments.isEmpty) {
    output = 'Hello';
  } else {
    output = 'Hello ${arguments.first}';
  }

  if (arguments.contains('--loud') || arguments.contains('-l')) {
    output = output.toUpperCase();
  }

  print(output);
}
