// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library dart_dev.src.tasks.link_dependency.api;

import 'dart:async';
import 'dart:io';
import 'dart:convert' show JSON;

import 'package:path/path.dart' as path;

import 'package:dart_dev/src/constants.dart';
import 'package:dart_dev/src/tasks/config.dart';
import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/util.dart' show hasImmediateDependency;

class LinkDependencyResult extends TaskResult {
  LinkDependencyResult() : super.success();
}

class LinkDependencyFailure implements Exception {}

class LinkDependencyTask extends Task {
  static const overridesKey = 'dependency_overrides';

  static bool isOverridesLine(String line) =>
      line.trim().startsWith(overridesKey);

  static Future<LinkDependencyTask> start(
      String packageName, Directory linkTarget) async {
    LinkDependencyTask task = new LinkDependencyTask._();
    task._run(packageName, linkTarget);
    return task;
  }

  static Future<LinkDependencyResult> run(
      String packageName, Directory linkTarget) async {
    LinkDependencyTask task = new LinkDependencyTask._();
    return task._run(packageName, linkTarget);
  }

  Stream<String> _dartdocStderr;
  Stream<String> _dartdocStdout;
  String _pubCommand;

  Completer<LinkDependencyResult> _done = new Completer();

  LinkDependencyTask._();

  Future<LinkDependencyResult> get done => _done.future;
  Stream<String> get errorOutput => _dartdocStderr;
  Stream<String> get output => _dartdocStdout;
  String get pubCommand => _pubCommand;

  Future<LinkDependencyResult> _run(
      String packageName, Directory linkTarget) async {
    var registry = _loadRegistry();

    if (packageName == null) {
      // Register the current directory if we didn't get a package name.
      registry[path.basename(Directory.current.path)] = Directory.current.path;
      _saveRegistry(registry);
    } else {
      if (!hasImmediateDependency(packageName)) {
        throw new ArgumentError(
            'Package "$packageName" is not a dependency for this project.');
      }

      // No link target provided, check the registry, if it isn't there,
      // go one directory up and try the package name.
      if (linkTarget == null) {
        linkTarget =
            new Directory(registry[packageName] ?? '../${packageName}');
      }
      if (!linkTarget.existsSync()) {
        throw new ArgumentError('Link target "${linkTarget
                .path}" does not exist. Try `ddev link <package> <directory>`.');
      }

      var pubspecLines = new File('pubspec.yaml').readAsLinesSync();
      var pubspecFile = new File('pubspec.yaml').openSync(mode: FileMode.WRITE);

      if (!pubspecLines.any(isOverridesLine)) {
        pubspecLines.add('$overridesKey:');
      }

      pubspecLines.forEach((line) {
        pubspecFile.writeStringSync('$line\n');
        if (isOverridesLine(line)) {
          pubspecFile
            ..writeStringSync('$linkStartFence\n')
            ..writeStringSync('  $packageName:\n')
            ..writeStringSync('    path: ${linkTarget.path}\n')
            ..writeStringSync('$linkEndFence\n');
        }
      });
    }

    _done.complete(new LinkDependencyResult());
    return _done.future;
  }

  Map<dynamic, dynamic> _loadRegistry() {
    var registryFile = new File(config.linkDependency.linkRegistryPath);
    return registryFile.existsSync()
        ? JSON.decode(registryFile.readAsStringSync())
        : {};
  }

  void _saveRegistry(Map<dynamic, dynamic> registry) {
    new File(config.linkDependency.linkRegistryPath)
        .writeAsStringSync(JSON.encode(registry));
  }
}
