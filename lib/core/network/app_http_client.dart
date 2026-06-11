import 'dart:io';

import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Builds the right HTTP client for the current platform.
///
/// On iOS/macOS we use [CupertinoClient] (Apple's NSURLSession). This matters:
/// Dart's built-in `dart:io` HttpClient is HTTP/1.1-only and opens a separate
/// TCP/TLS connection per concurrent request. WooCommerce hosts (behind
/// Cloudflare/LiteSpeed) cap simultaneous connections per IP and speak HTTP/2,
/// so a burst of parallel requests on iOS exhausts the connection limit and the
/// extras hang until they time out. NSURLSession speaks HTTP/2 and multiplexes
/// every request over a single connection, sidestepping the limit entirely and
/// handling pooling/reuse natively.
///
/// On Android and other platforms `dart:io` works well, so we keep it (with a
/// shared, pooled [IOClient]).
http.Client createAppHttpClient() {
  if (Platform.isIOS || Platform.isMacOS) {
    return CupertinoClient.defaultSessionConfiguration();
  }
  return IOClient(
    HttpClient()..idleTimeout = const Duration(seconds: 15),
  );
}
