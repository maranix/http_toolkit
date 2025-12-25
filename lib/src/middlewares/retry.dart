import 'dart:async';
import 'dart:math';
import 'package:http/http.dart';
import '../middleware.dart';
import '../utils/request_copier.dart';

/// A strategy for calculating delay durations between retry attempts.
///
/// Implement this interface to create custom backoff strategies for
/// [RetryMiddleware].
///
/// ## Built-in Strategies
///
/// - [FixedDelayStrategy] - Same delay for every retry
/// - [LinearBackoffStrategy] - Delay increases linearly (1x, 2x, 3x, ...)
/// - [ExponentialBackoffStrategy] - Delay doubles each time (1x, 2x, 4x, 8x, ...)
///
/// ## Custom Strategy Example
///
/// ```dart
/// class JitteredBackoffStrategy implements BackoffStrategy {
///   const JitteredBackoffStrategy({this.baseDelay = const Duration(seconds: 1)});
///   final Duration baseDelay;
///
///   @override
///   Duration getDelayDuration(int attempt) {
///     final exponentialDelay = baseDelay.inMilliseconds * pow(2, attempt - 1);
///     final jitter = Random().nextInt(exponentialDelay ~/ 2);
///     return Duration(milliseconds: exponentialDelay.toInt() + jitter);
///   }
/// }
/// ```
abstract interface class BackoffStrategy {
  const BackoffStrategy();

  /// Returns the delay duration before the next retry attempt.
  ///
  /// [attempt] is the 1-indexed retry attempt number (1 for first retry,
  /// 2 for second retry, etc.).
  Duration getDelayDuration(int attempt);
}

/// A backoff strategy that waits for a fixed duration between retries.
///
/// Use this when you want consistent delays between retries, regardless
/// of how many attempts have been made.
///
/// ## When to Use
///
/// - Simple retry scenarios with known delay requirements
/// - When the server suggests a specific retry-after duration
/// - Testing and development (predictable timing)
///
/// ## Example
///
/// ```dart
/// RetryMiddleware(
///   maxRetries: 3,
///   strategy: const FixedDelayStrategy(Duration(seconds: 2)),
/// )
/// // Delays: 2s, 2s, 2s
/// ```
///
/// ## Better Alternative
///
/// For production use, consider [ExponentialBackoffStrategy] to avoid
/// overwhelming a recovering server with rapid retries.
class FixedDelayStrategy implements BackoffStrategy {
  /// Creates a fixed delay strategy.
  ///
  /// [delay] is the duration to wait between each retry attempt.
  const FixedDelayStrategy(this.delay);

  /// The fixed duration to wait between retries.
  final Duration delay;

  @override
  Duration getDelayDuration(int attempt) => delay;
}

/// A backoff strategy with linearly increasing delay between retries.
///
/// The delay increases by the initial delay for each attempt:
/// attempt 1 = initialDelay, attempt 2 = 2x, attempt 3 = 3x, etc.
///
/// ## When to Use
///
/// - Moderate backoff needs without aggressive exponential growth
/// - When you want predictable delay progression
///
/// ## Example
///
/// ```dart
/// RetryMiddleware(
///   maxRetries: 3,
///   strategy: const LinearBackoffStrategy(Duration(seconds: 1)),
/// )
/// // Delays: 1s, 2s, 3s
/// ```
///
/// ## Comparison with Exponential
///
/// Linear: 1s → 2s → 3s → 4s → 5s
/// Exponential: 1s → 2s → 4s → 8s → 16s
///
/// Use linear for gentler backoff; exponential for better server protection.
class LinearBackoffStrategy implements BackoffStrategy {
  /// Creates a linear backoff strategy.
  ///
  /// [initialDelay] is the base delay that gets multiplied by the attempt count.
  const LinearBackoffStrategy(this.initialDelay);

  /// The base delay that gets multiplied by the attempt number.
  final Duration initialDelay;

  @override
  Duration getDelayDuration(int attempt) => initialDelay * attempt;
}

/// A backoff strategy with exponentially increasing delay between retries.
///
/// The delay doubles with each attempt: 1x, 2x, 4x, 8x, etc.
/// This is the recommended strategy for production systems.
///
/// ## When to Use
///
/// - Production API clients
/// - When you want to avoid overwhelming a recovering server
/// - Rate-limited APIs
///
/// ## Example
///
/// ```dart
/// RetryMiddleware(
///   maxRetries: 4,
///   strategy: const ExponentialBackoffStrategy(
///     initialDelay: Duration(milliseconds: 500),
///   ),
/// )
/// // Delays: 500ms, 1s, 2s, 4s
/// ```
///
/// ## Formula
///
/// `delay = initialDelay * 2^(attempt - 1)`
///
/// ## Better Alternative for High Scale
///
/// For very high-scale systems, consider implementing a custom strategy
/// with jitter to prevent thundering herd problems when many clients
/// retry simultaneously.
class ExponentialBackoffStrategy implements BackoffStrategy {
  /// Creates an exponential backoff strategy.
  ///
  /// [initialDelay] defaults to 500ms, which results in:
  /// 500ms → 1s → 2s → 4s → 8s → ...
  const ExponentialBackoffStrategy({
    this.initialDelay = const Duration(milliseconds: 500),
  });

  /// The starting delay for the first retry attempt.
  final Duration initialDelay;

  @override
  Duration getDelayDuration(int attempt) {
    return Duration(
      milliseconds: initialDelay.inMilliseconds * pow(2, attempt - 1).toInt(),
    );
  }
}

/// A middleware that automatically retries failed HTTP requests.
///
/// This middleware intercepts network errors and optionally status-based
/// failures, retrying the request according to the configured strategy.
///
/// ## When to Use
///
/// - Handling transient network failures
/// - APIs that occasionally return 5xx errors during high load
/// - Improving reliability of critical HTTP operations
///
/// ## Default Behavior
///
/// By default, the middleware:
/// - Retries up to 3 times
/// - Uses exponential backoff starting at 500ms
/// - Retries on any exception (network errors)
/// - Does NOT retry based on response status codes (only exceptions)
///
/// ## Retry Callbacks
///
/// Use [whenError] and [whenResponse] to customize retry behavior:
///
/// ```dart
/// RetryMiddleware(
///   maxRetries: 3,
///   whenError: (error, attempt, nextDelay) {
///     print('Attempt $attempt failed: $error');
///     print('Retrying in ${nextDelay.inSeconds}s...');
///     return true; // Return true to retry, false to stop
///   },
///   whenResponse: (response, attempt, elapsed) {
///     // Retry on server errors
///     if (response.statusCode >= 500) {
///       print('Server error, retrying...');
///       return true;
///     }
///     return false;
///   },
/// )
/// ```
///
/// ## Callback Parameters
///
/// ### whenError(error, attempt, nextDelay)
/// - `error`: The exception that was thrown
/// - `attempt`: The current attempt number (1-indexed)
/// - `nextDelay`: The duration that will be waited before the next retry
///
/// ### whenResponse(response, attempt, elapsed)
/// - `response`: The HTTP response received
/// - `attempt`: The current attempt number (1-indexed)
/// - `elapsed`: The delay duration for this attempt
///
/// ## Example: Retry on 5xx with Logging
///
/// ```dart
/// final client = Client(
///   middlewares: [
///     RetryMiddleware(
///       maxRetries: 3,
///       strategy: const ExponentialBackoffStrategy(
///         initialDelay: Duration(seconds: 1),
///       ),
///       whenError: (error, attempt, nextDelay) {
///         log.warning('Request failed on attempt $attempt: $error');
///         return true; // Retry all errors
///       },
///       whenResponse: (response, attempt, elapsed) {
///         if (response.statusCode >= 500) {
///           log.warning('Server error ${response.statusCode}, retrying...');
///           return true; // Retry server errors
///         }
///         return false; // Don't retry client errors or success
///       },
///     ),
///   ],
/// );
/// ```
class RetryMiddleware implements Middleware {
  /// Creates a retry middleware.
  ///
  /// [maxRetries] is the maximum number of retry attempts (default: 3).
  /// [strategy] determines the delay between retries (default: exponential).
  /// [whenError] is called on exceptions to decide if retry should occur.
  /// [whenResponse] is called on responses to decide if retry should occur.
  const RetryMiddleware({
    this.maxRetries = 3,
    this.strategy = const ExponentialBackoffStrategy(),
    this.whenError,
    this.whenResponse,
  });

  /// Maximum number of retry attempts (excludes the initial request).
  final int maxRetries;

  /// The backoff strategy for calculating delays between retries.
  final BackoffStrategy strategy;

  /// Callback to determine whether to retry after an exception.
  ///
  /// Parameters:
  /// - `error`: The exception that was thrown
  /// - `attempt`: Current attempt number (1-indexed)
  /// - `nextAttempt`: Duration until the next retry attempt
  ///
  /// Return `true` to retry, `false` to stop retrying and rethrow the error.
  ///
  /// If not provided, all exceptions trigger a retry (up to maxRetries).
  final bool Function(Object error, int attempt, Duration nextAttempt)?
  whenError;

  /// Callback to determine whether to retry based on the response.
  ///
  /// Parameters:
  /// - `response`: The HTTP response received
  /// - `attempt`: Current attempt number (1-indexed)
  /// - `totalDuration`: The delay duration for this attempt
  ///
  /// Return `true` to retry, `false` to accept the response.
  ///
  /// If not provided, responses are never retried (only exceptions).
  final bool Function(
    BaseResponse response,
    int attempt,
    Duration totalDuration,
  )?
  whenResponse;

  @override
  Future<StreamedResponse> handle(BaseRequest request, Handler next) async {
    var attempts = 0;

    while (true) {
      attempts++;

      final duration = strategy.getDelayDuration(attempts);

      final currentRequest = (attempts == 1) ? request : copyRequest(request);

      try {
        final response = await next(currentRequest);
        if (attempts <= maxRetries &&
            whenResponse != null &&
            whenResponse!(
              response,
              attempts,
              duration,
            )) {
          await Future.wait([
            response.stream.drain<void>(),
            _delayBy(duration),
          ]);

          continue;
        }
        return response;
      } catch (e) {
        final delayDuration = strategy.getDelayDuration(attempts);

        if (attempts > maxRetries ||
            (whenError != null && !whenError!(e, attempts, delayDuration))) {
          if (whenError == null && attempts <= maxRetries) {
            await _delayBy(delayDuration);
            continue;
          }
          rethrow;
        }

        await _delayBy(delayDuration);
      }
    }
  }

  Future<void> _delayBy(Duration duration) {
    return Future.delayed(duration);
  }
}
