import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

/// A Dio [HttpClientAdapter] that performs requests through a `package:http`
/// [http.Client]. This lets Dio use platform-native transports (e.g.
/// `cupertino_http`/NSURLSession on iOS) instead of `dart:io`, which fixes the
/// iOS connection-starvation hang on bursts of parallel requests.
class HttpToDioAdapter implements HttpClientAdapter {
  final http.Client _client;

  HttpToDioAdapter(this._client);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final request = http.Request(options.method, options.uri);

    // Copy headers (Dio header values may be String or List).
    options.headers.forEach((key, value) {
      if (value == null) return;
      request.headers[key] =
          value is Iterable ? value.join(',') : value.toString();
    });

    if (requestStream != null) {
      final chunks = await requestStream.toList();
      final bytes = <int>[];
      for (final c in chunks) {
        bytes.addAll(c);
      }
      request.bodyBytes = Uint8List.fromList(bytes);
    }

    request.followRedirects = options.followRedirects;
    request.maxRedirects = options.maxRedirects;

    // Apply the connect timeout as an overall send guard; Dio applies the
    // receive timeout itself while reading the response stream.
    final connectTimeout = options.connectTimeout;
    var sendFuture = _client.send(request);
    if (connectTimeout != null && connectTimeout > Duration.zero) {
      sendFuture = sendFuture.timeout(connectTimeout);
    }

    final streamed = await sendFuture;

    final headers = <String, List<String>>{};
    streamed.headers.forEach((key, value) => headers[key] = [value]);

    return ResponseBody(
      streamed.stream.map(Uint8List.fromList),
      streamed.statusCode,
      headers: headers,
      statusMessage: streamed.reasonPhrase,
      isRedirect: streamed.isRedirect,
    );
  }

  @override
  void close({bool force = false}) => _client.close();
}
