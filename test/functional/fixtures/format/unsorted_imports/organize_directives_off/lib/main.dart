import 'package:meta/meta.dart';
import 'dart:async';

void doStuff({@required String content}) async {
  await Future.delayed(Duration(seconds: 1));
  print(content);
}
