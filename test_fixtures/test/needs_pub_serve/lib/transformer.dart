library needs_pub_serve.transformer;

import 'dart:async';

import 'package:barback/barback.dart';

class FalseToTrueTransformer extends Transformer {
  FalseToTrueTransformer.asPlugin();

  @override
  String get allowedExtensions => '.dart';

  @override
  Future apply(Transform transform) async {
    var contents = await transform.primaryInput.readAsString();
    var transformedContents = contents.replaceAll(
        'bool wasTransformed = false', 'bool wasTransformed = true');
    transform.addOutput(
        new Asset.fromString(transform.primaryInput.id, transformedContents));
  }
}
