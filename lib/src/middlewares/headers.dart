import 'package:http/http.dart';
import '../middleware.dart';

/// Middleware that merges default headers into every request.
///
/// This middleware adds the specified [headers] to every request.
/// If a header already exists in the request, it is **overwritten** by the value
/// specified here.
///
/// ## Example
///
/// ```dart
/// client = Client(
///   middlewares: [
///     const HeadersMiddleware(headers: {
///       'User-Agent': 'MyApp/1.0',
///       'Accept': 'application/json',
///     }),
///   ],
/// );
/// ```
class HeadersMiddleware implements RequestMiddleware {
  /// Creates a middleware that injects the given [headers].
  const HeadersMiddleware({required this.headers});

  /// The map of headers to add to each request.
  final Map<String, String> headers;

  @override
  void onRequest(BaseRequest request) {
    request.headers.addAll(headers);
  }
}
