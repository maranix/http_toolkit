import 'dart:async';
import 'dart:math';
import 'package:http/http.dart';
import '../middleware.dart';

/// A middleware that retries requests on failure.
class RetryMiddleware {
  final int maxRetries;
  final Duration Function(int retryCount)? delay;
  final bool Function(Object error)? whenError;
  final bool Function(BaseResponse response)? whenResponse;

  const RetryMiddleware({
    this.maxRetries = 3,
    this.delay,
    this.whenError,
    this.whenResponse,
  });

  Future<StreamedResponse> call(BaseRequest request, Handler next) async {
    int attempts = 0;
    while (true) {
      attempts++;
      // For the first attempt, use the original request.
      // For subsequent attempts, we MUST clone the request because the previous one was finalized.
      final currentRequest = (attempts == 1) ? request : _copyRequest(request);

      try {
        final response = await next(currentRequest);
        if (attempts <= maxRetries &&
            whenResponse != null &&
            whenResponse!(response)) {
          // Retry based on response (e.g., 503)
          // We must consume the response stream before retrying to avoid leaking connections?
          // BaseClient/inner usually handles it, but if we discard response, we should probably drain it.
          // response.stream.drain(); // Good practice
          await response.stream.drain<void>();

          await _delay(attempts);
          continue;
        }
        return response;
      } catch (e) {
        if (attempts > maxRetries || (whenError != null && !whenError!(e))) {
          rethrow;
        }
        await _delay(attempts);
      }
    }
  }

  Future<void> _delay(int attempt) {
    if (delay != null) {
      return Future.delayed(delay!(attempt));
    }
    // Default exponential backoff: 500ms, 1s, 2s...
    final duration = Duration(milliseconds: 500 * pow(2, attempt - 1).toInt());
    return Future.delayed(duration);
  }

  BaseRequest _copyRequest(BaseRequest request) {
    BaseRequest requestCopy;

    if (request is Request) {
      requestCopy = Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is MultipartRequest) {
      requestCopy = MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is StreamedRequest) {
      // StreamedRequests cannot be copied easily as the stream is single-subscription.
      throw StateError('Cannot retry a StreamedRequest.');
    } else {
      // Fallback for other types?
      throw StateError(
        'Unsupported request type for retry: ${request.runtimeType}',
      );
    }

    requestCopy.headers.addAll(request.headers);
    requestCopy.followRedirects = request.followRedirects;
    requestCopy.maxRedirects = request.maxRedirects;
    requestCopy.persistentConnection = request.persistentConnection;

    return requestCopy;
  }
}
