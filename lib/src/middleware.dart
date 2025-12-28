/// @docImport 'package:http_toolkit/http_toolkit.dart';
library;

import 'dart:async';

import 'package:http/http.dart' as http;

/// A function that handles a request and returns a response.
///
/// This is the core function signature for the HTTP request pipeline.
typedef RequestHandler =
    Future<http.StreamedResponse> Function(http.BaseRequest request);

/// The base marker interface for all middleware types.
///
/// Do not implement this directly. Implement one of the specific sub-interfaces:
/// *   [RequestMiddleware]
/// *   [RequestTransformerMiddleware]
/// *   [ResponseMiddleware]
/// *   [AsyncMiddleware]
abstract interface class Middleware {}

/// A middleware that runs purely for side-effects before a request is sent.
///
/// ## Purpose
/// Use this when you need to observe a request but do not need to modify it or
/// wait for the response.
///
/// ## Behavior
/// *   Runs synchronously.
/// *   Cannot modify the request object reference (though it can mutate mutable properties if really needed, prefer Transformers for that).
/// *   Cannot block or delay the request.
/// *   Executes in **FIFO** order.
///
/// ## Use Cases
/// *   Logging "Request Started" events.
/// *   Updating internal metrics or counters.
abstract interface class RequestMiddleware implements Middleware {
  /// Called before the request is sent.
  void onRequest(http.BaseRequest request);
}

/// A middleware that transforms the request object before it is sent.
///
/// ## Purpose
/// Use this when you need to modify the request, such as adding headers,
/// changing the URL, or replacing the body.
///
/// ## Behavior
/// *   Returns a new [http.BaseRequest] (or the same one if no changes).
/// *   Executes in **LIFO** order (wrapping later middlewares).
/// *   Can safely clone requests.
///
/// ## Use Cases
/// *   Resolving relative URLs [BaseUrlMiddleware].
/// *   Injecting Authentication headers [BearerAuthMiddleware].
/// *   Compressing request bodies.
abstract interface class RequestTransformerMiddleware implements Middleware {
  /// Transforms the request and returns the version to be sent.
  http.BaseRequest onRequest(http.BaseRequest request);
}

/// A middleware that processes the response after it is received.
///
/// ## Purpose
/// Use this to observe or modify the response stream.
///
/// ## Behavior
/// *   Returns a [http.StreamedResponse].
/// *   Executes in **LIFO** order.
/// *   **Warning:** Modifying the response stream body requires reading and repacking it,
///     which can be expensive.
///
/// ## Use Cases
/// *   Global error handling (validating status codes).
/// *   Logging response metadata.
abstract interface class ResponseMiddleware implements Middleware {
  /// processes the response.
  http.StreamedResponse onResponse(
    http.StreamedResponse response,
  );
}

/// A middleware that wraps the entire request lifecycle asynchronously.
///
/// ## Purpose
/// This is the most powerful middleware type, capable of handling the request
/// before it's sent, the response after it's received, and any errors thrown.
///
/// ## Behavior
/// *   Takes the `next` handler as an argument.
/// *   Can decide *not* to call `next` (e.g., returning a cached response).
/// *   Can call `next` multiple times (e.g., Retries).
/// *   Executes in **LIFO** order.
///
/// ## Use Cases
/// *   [RetryMiddleware]: Catch errors and retry.
/// *   [LoggerMiddleware]: Measure total duration of the request.
/// *   Caching layers.
abstract interface class AsyncMiddleware implements Middleware {
  /// Handles the request execution.
  ///
  /// Call [next(request)] to proceed to the next middleware in the chain.
  Future<http.StreamedResponse> handle(
    http.BaseRequest request,
    RequestHandler next,
  );
}
