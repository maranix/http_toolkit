/// @docImport 'package:http_toolkit/http_toolkit.dart';
/// A powerful, composable HTTP client wrapper for Dart.
///
/// `http_toolkit` provides a robust "missing battery" layer for the standard `http` package,
/// enabling advanced features like **Interceptors**, **Middleware Pipelines**, and **Extensions**
/// while maintaining maximum compatibility with `http.BaseClient`.
///
/// ## Key Features
///
/// *   **Client**: A drop-in replacement for `http.Client` that supports middleware and interceptors.
/// *   **Interceptors**: Modify requests, responses, and handle errors at a low level.
/// *   **Middlewares**: Compose high-level behaviors (Authentication, Logging, Retries).
/// *   **Extensions**: Convenient helpers for JSON parsing and status code checks.
///
/// ## Built-in Middlewares
///
/// *   [RetryMiddleware]: Automatically retries failed requests with exponential backoff.
/// *   [LoggerMiddleware]: Logs request and response details for debugging.
/// *   [BearerAuthMiddleware] / [BasicAuthMiddleware]: Simple authentication injection.
/// *   [HeadersMiddleware]: Applies default headers to every request.
///
/// ## Usage
///
/// ```dart
/// import 'package:http_toolkit/http_toolkit.dart';
///
/// void main() async {
///   final client = Client(
///     middlewares: [
///       const LoggerMiddleware(logBody: true),
///       const RetryMiddleware(maxRetries: 3),
///       const BearerAuthMiddleware('my-token'),
///     ],
///   );
///
///   final response = await client.get(Uri.parse('https://api.example.com/data'));
///   print(response.jsonMap);
/// }
/// ```
library;

export 'package:http/http.dart'
    hide Client; // Export http package for convenience as requested

export 'src/client.dart';
export 'src/extensions.dart';
export 'src/interceptor.dart';
export 'src/middleware.dart';
export 'src/middlewares/auth.dart';
export 'src/middlewares/base_url.dart';
export 'src/middlewares/headers.dart';
export 'src/middlewares/logger.dart';
export 'src/middlewares/retry.dart';
export 'src/response_validator.dart';
