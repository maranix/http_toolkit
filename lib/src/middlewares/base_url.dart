import 'package:http/http.dart' as http;
import 'package:http_toolkit/src/extension.dart';
import 'package:http_toolkit/src/middleware.dart';

/// A request transformer that injects a base URL into requests.
///
/// This middleware checks if the request URL matches the base URL's scheme and host.
/// If the request URL is relative (or just a path), it resolves it against the [baseUrl].
///
/// ## Resolution Logic
///
/// It uses [Uri.resolveUri] to combine the [baseUrl] with the incoming request's URL.
///
/// ## Example
///
/// ```dart
/// // Setup
/// final client = Client(
///   middlewares: [
///     const BaseUrlMiddleware('https://api.example.com/v1/'),
///   ],
/// );
///
/// // Usage
/// // Request becomes: https://api.example.com/v1/users?id=123
/// client.get(Uri.parse('users?id=123'));
/// ```
final class BaseUrlMiddleware implements RequestTransformerMiddleware {
  /// Creates a middleware to resolve requests against [baseUrl].
  const BaseUrlMiddleware(this.baseUrl);

  /// The base URL to inject. Should usually end with a slash `/` if it includes a path.
  final String baseUrl;

  @override
  http.BaseRequest onRequest(http.BaseRequest request) {
    if (request is! http.Request) {
      return request;
    }

    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null) {
      throw ArgumentError('Invalid base URL: $baseUrl');
    }

    final newUri = baseUri.resolveUri(request.url);
    return request.cloneWith(uri: newUri);
  }
}
