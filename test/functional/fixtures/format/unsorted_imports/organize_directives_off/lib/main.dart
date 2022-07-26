import 'package:test/test.dart';
import 'dart:async';

void doStuff({TestFailure t}) async {
  await Future.delayed(Duration(seconds: 1));
  print(t.message);
}
