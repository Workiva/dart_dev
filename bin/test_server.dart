import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

// Some graph_ui tests fail with this on default settings. Seems to be because something is getting overlodaed. Running
// with -j 1 or 2 they run fine. But -j 1 seems to make no difference in performance, so might as well use it. This
// actually seems a bit faster, just on the test part, than the test part of build_runner test.

// Get the package name from the current directory name, used to find the directory to serve inside build/generated.
String packageName = p.basename(Directory.current.path);

// This seems slow, and if I don't run with -j 1, it can fail. I suspect it might be an issue in this server blocking or
// having a race condition, but not clear.

// TODO: parse args and allow this to be specified.
int servePort = 8088;

int pubServePort = 8080;

void main() async {
  var proxy = proxyHandler('http://localhost:$pubServePort');
  var handler = Cascade()
      .add(createStaticHandler('.'))
      .add(createStaticHandler('test'))
      .add(createStaticHandler('.dart_tool/build/generated/$packageName/test'))
      .add(proxy) // I think this is just needed for source code in /packages.
      .handler;
  var pipeline = const Pipeline()
      .addMiddleware(logRequests(logger: logErrors))
      .addMiddleware(rewriteTests())
      .addHandler(handler);
  var server = await shelf_io.serve(pipeline, 'localhost', servePort);

  print('Proxying at http://${server.address.host}:${server.port}');
}

// Just log errors, so it isn't overwhelming.
void logErrors(String msg, bool isError) {
  if (isError) {
    print('[ERROR] $msg');
  } else {
    //  print(msg);
  }
}

// Some of the test files need to be rewritten, because what we get from
// a serve isn't the same as what we'd get by creating a merged test directory. Not
// especially clear why/what? Should look at exactly what creating the merged directory
// does.
Middleware rewriteTests() {
  return (innerHandler) {
    return (request) async {
      var newRequest = await rewrite(request);
      return innerHandler(newRequest ?? request);
    };
  };
}

// If we see we end with the key, then we insert the value after the _test
var replacementRules = {
  // 'webdev serve' serves them up with the debug extension. Does that make a difference? Can we make it not do that?
  '_test.html': '_test.debug.html',
  // This seems to be necessary for some packages (microfrontend) but not others graph_ui. Presumably this is related to
  // package:test expecting dart2js compilation, but I don't understand why the difference. Are there other files like this?
  '_test.dart.js.map': '_test.unsound.ddc.js.map'
};

// TODO: Shouldn't this be the same list as what we have in the cascade above?
var knownDirectories = [
  'test',
  // This seems to be necessary for some packages (microfrontend) but not others (graph_ui).
  '.dart_tool/build/generated/$packageName/test',
];

/// Rewrite a request to check if the path needs to be modified.
Future<Request> rewrite(Request request) async {
  // This is a silly way to do this. We're hard-coding the directories here, and then making static servers for them,
  // because I don't know how to make the rewrite happen within the handler and I don't want to inline all of the static
  // server code.

  // First, check if the file exists in the directories that we just serve statically.
  var path = request.url.path;
  for (var dir in knownDirectories) {
    var filePath = p.join(dir, path);
    if (await File(filePath).exists()) {
      return request;
    }
  }

  // For each pattern in [replacements], if the path matches it, rewrite it
  // and return a modified request.
  Request newRequest;
  for (var pattern in replacementRules.keys) {
    if (path.endsWith(pattern)) {
      newRequest =
          await rewriteFrom(pattern, replacementRules[pattern], request);
    }
  }
  return newRequest;
}

// We already know that [file] ends with [pattern]. Replace [pattern] with [replacement], and return a new request.
Future<Request> rewriteFrom(
    String pattern, String replacement, Request request) async {
  var path = request.url.path;
  var firstPart = path.substring(0, path.length - pattern.length);
  var newPath = '$firstPart$replacement';
  var newUrl = request.requestedUri.replace(path: newPath);
  print("Rewrote $path into $newPath");
  return Request('GET', newUrl);
}

///-------------------------------------------------------------------------------------------------------
///-------------------------------------------------------------------------------------------------------
///-------------------------------- This is just copied from shelf_proxy because its prereqs are a problem
///-------------------------------- Get rid of it.
///-------------------------------------------------------------------------------------------------------
///-------------------------------------------------------------------------------------------------------
////// A handler that proxies requests to [url].
///
/// To generate the proxy request, this concatenates [url] and [Request.url].
/// This means that if the handler mounted under `/documentation` and [url] is
/// `http://example.com/docs`, a request to `/documentation/tutorials`
/// will be proxied to `http://example.com/docs/tutorials`.
///
/// [url] must be a [String] or [Uri].
///
/// [client] is used internally to make HTTP requests. It defaults to a
/// `dart:io`-based client.
///
/// [proxyName] is used in headers to identify this proxy. It should be a valid
/// HTTP token or a hostname. It defaults to `shelf_proxy`.
Handler proxyHandler(url, {http.Client client, String proxyName}) {
  Uri uri;
  if (url is String) {
    uri = Uri.parse(url);
  } else if (url is Uri) {
    uri = url;
  } else {
    throw ArgumentError.value(url, 'url', 'url must be a String or Uri.');
  }
  final nonNullClient = client ?? http.Client();
  proxyName ??= 'shelf_proxy';

  return (serverRequest) async {
    // TODO(nweiz): Support WebSocket requests.

    // TODO(nweiz): Handle TRACE requests correctly. See
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.8
    final requestUrl = uri.resolve(serverRequest.url.toString());
    final clientRequest = http.StreamedRequest(serverRequest.method, requestUrl)
      ..followRedirects = false
      ..headers.addAll(serverRequest.headers)
      ..headers['Host'] = uri.authority;

    // Add a Via header. See
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.45
    _addHeader(clientRequest.headers, 'via',
        '${serverRequest.protocolVersion} $proxyName');

    serverRequest
        .read()
        .forEach(clientRequest.sink.add)
        .catchError(clientRequest.sink.addError)
        .whenComplete(clientRequest.sink.close);
    final clientResponse = await nonNullClient.send(clientRequest);
    // Add a Via header. See
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.45
    _addHeader(clientResponse.headers, 'via', '1.1 $proxyName');

    // Remove the transfer-encoding since the body has already been decoded by
    // [client].
    clientResponse.headers.remove('transfer-encoding');

    // If the original response was gzipped, it will be decoded by [client]
    // and we'll have no way of knowing its actual content-length.
    if (clientResponse.headers['content-encoding'] == 'gzip') {
      clientResponse.headers.remove('content-encoding');
      clientResponse.headers.remove('content-length');

      // Add a Warning header. See
      // http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.5.2
      _addHeader(
          clientResponse.headers, 'warning', '214 $proxyName "GZIP decoded"');
    }

    // Make sure the Location header is pointing to the proxy server rather
    // than the destination server, if possible.
    if (clientResponse.isRedirect &&
        clientResponse.headers.containsKey('location')) {
      final location =
          requestUrl.resolve(clientResponse.headers['location']).toString();
      if (p.url.isWithin(uri.toString(), location)) {
        clientResponse.headers['location'] =
            '/${p.url.relative(location, from: uri.toString())}';
      } else {
        clientResponse.headers['location'] = location;
      }
    }

    return Response(clientResponse.statusCode,
        body: clientResponse.stream, headers: clientResponse.headers);
  };
}

// TODO(nweiz): use built-in methods for this when http and shelf support them.
/// Add a header with [name] and [value] to [headers], handling existing headers
/// gracefully.
void _addHeader(Map<String, String> headers, String name, String value) {
  final existing = headers[name];
  headers[name] = existing == null ? value : '$existing, $value';
}
