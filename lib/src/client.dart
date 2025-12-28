import 'dart:async';
import 'package:http/http.dart' as http;
import 'middleware.dart';

/// A powerful, composable HTTP client wrapper.
///
/// The [Client] wraps a standard [http.Client] and executes a pipeline of
/// [Middleware] for every request. It allows you to compose behaviors like
/// authentication, logging, retries, and base URL resolution in a declarative way.
///
/// ## Middleware Pipeline Order
///
/// The middleware pipeline is executed in a specific order to ensure predictable behavior:
///
/// 1.  **Async Middlewares**: These wrap the entire request execution. They are versatile and can
///     perform pre-request work, post-response work, error handling, and retries.
///     *   Executed in **LIFO (Last-In-First-Out)** order (like onion layers).
///     *   Example: `RetryMiddleware`, `LoggerMiddleware` (Request duration).
//
/// 2.  **Request Middlewares**: Synchronous side-effects before the request is sent.
///     *   Executed in **FIFO (First-In-First-Out)** order.
///     *   Useful for logging request details or updating external state.
///     *   *Cannot* modify the request explicitly (use Transformers for that).
///
/// 3.  **Request Transformer Middlewares**: Modify the request object before it is sent.
///     *   Executed in **LIFO (Last-In-First-Out)** order.
///     *   This allows later middlewares to wrap earlier ones (e.g., a specific API client
///         wrapping a base client might want its BaseURL to take precedence).
///     *   Example: `BaseUrlMiddleware`, `BearerAuthMiddleware` (via header injection).
///
/// 4.  **Network Call**: The inner [http.Client] sends the request.
///
/// 5.  **Response Middlewares**: Process implementation-specific response logic.
///     *   Executed in **LIFO (Last-In-First-Out)** order.
///     *   Example: Global error checking (throwing on 401).
///
/// ## Example
///
/// ```dart
/// final client = Client(
///   middlewares: [
///     const RetryMiddleware(maxRetries: 3), // (1) Outer layer (Async)
///     const LoggerMiddleware(),             // (2) Inner layer (Async)
///     const BaseUrlMiddleware('...'),       // (3) Request Transformer
///   ],
/// );
/// ```
class Client extends http.BaseClient {
  /// Creates a new HTTP Toolkit client.
  ///
  /// [inner] is the underlying [http.Client] used to send requests. Defaults to `http.Client()`.
  /// [middlewares] is the list of middleware to apply to every request.
  Client({
    http.Client? inner,
    List<Middleware> middlewares = const [],
  }) : _inner = inner ?? http.Client() {
    _handler = _composeHandler(_inner.send, middlewares);
  }

  final http.Client _inner;
  late final RequestHandler _handler;

  static RequestHandler _composeHandler(
    RequestHandler innerHandler,
    List<Middleware> middlewares,
  ) {
    if (middlewares.isEmpty) {
      return innerHandler;
    }

    var handler = innerHandler;

    // Filter Async, Request and Response middlewares ahead of handler composition
    final asyncMiddlewares = <AsyncMiddleware>[];
    final requestMiddlewares = <RequestMiddleware>[];
    final requestTransformers = <RequestTransformerMiddleware>[];
    final responseMiddlewares = <ResponseMiddleware>[];

    for (var i = 0; i < middlewares.length; i++) {
      final middleware = middlewares[i];

      switch (middleware) {
        case AsyncMiddleware _:
          asyncMiddlewares.add(middleware);
        case RequestMiddleware _:
          requestMiddlewares.add(middleware);
        case RequestTransformerMiddleware _:
          requestTransformers.add(middleware);
        case ResponseMiddleware _:
          responseMiddlewares.add(middleware);
      }
    }

    handler = _wrapAsyncMiddlewares(handler, asyncMiddlewares);

    return (http.BaseRequest request) async {
      for (var i = 0; i < requestMiddlewares.length; i++) {
        requestMiddlewares[i].onRequest(request);
      }

      for (var i = requestTransformers.length - 1; i >= 0; i--) {
        request = requestTransformers[i].onRequest(request);
      }

      var response = await handler(request);

      for (var i = responseMiddlewares.length - 1; i >= 0; i--) {
        response = responseMiddlewares[i].onResponse(response);
      }

      return response;
    };
  }

  static RequestHandler _wrapAsyncMiddlewares(
    RequestHandler handler,
    List<AsyncMiddleware> middlewares,
  ) {
    if (middlewares.isEmpty) {
      return handler;
    }

    var h = handler;

    for (var i = middlewares.length - 1; i >= 0; i--) {
      final middleware = middlewares[i];
      final next = h;

      h = (request) => middleware.handle(request, next);
    }

    return h;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
