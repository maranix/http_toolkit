import 'dart:async';
import 'dart:math';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import '../middleware.dart';
import '../utils/request_copier.dart';

/// A strategy for calculating the delay before the next retry.
abstract interface class BackoffStrategy {
  const BackoffStrategy();

  Duration getDelay(int attempt);
}

/// A strategy that waits for a fixed duration.
class FixedDelayStrategy implements BackoffStrategy {
  const FixedDelayStrategy(this.delay);
  final Duration delay;

  @override
  Duration getDelay(int attempt) => delay;
}

/// A strategy that waits for a duration that increases linearly with the attempt count.
@reopen
class LinearBackoffStrategy extends BackoffStrategy {
  const LinearBackoffStrategy(this.initialDelay);
  final Duration initialDelay;

  @override
  Duration getDelay(int attempt) => initialDelay * attempt;
}

/// A strategy that waits for a duration that increases exponentially with the attempt count.
@reopen
class ExponentialBackoffStrategy extends BackoffStrategy {
  const ExponentialBackoffStrategy({
    this.initialDelay = const Duration(milliseconds: 500),
  });
  final Duration initialDelay;

  @override
  Duration getDelay(int attempt) {
    return Duration(
      milliseconds: initialDelay.inMilliseconds * pow(2, attempt - 1).toInt(),
    );
  }
}

/// A middleware that retries requests on failure.
class RetryMiddleware implements Middleware {
  const RetryMiddleware({
    this.maxRetries = 3,
    this.strategy = const ExponentialBackoffStrategy(),
    this.whenError,
    this.whenResponse,
  });
  final int maxRetries;
  final BackoffStrategy strategy;
  final bool Function(Object error)? whenError;
  final bool Function(BaseResponse response)? whenResponse;

  @override
  Future<StreamedResponse> handle(BaseRequest request, Handler next) async {
    var attempts = 0;
    while (true) {
      attempts++;

      final currentRequest = (attempts == 1) ? request : copyRequest(request);

      try {
        final response = await next(currentRequest);
        if (attempts <= maxRetries &&
            whenResponse != null &&
            whenResponse!(response)) {
          await response.stream.drain<void>();
          await _delay(attempts);
          continue;
        }
        return response;
      } catch (e) {
        if (attempts > maxRetries || (whenError != null && !whenError!(e))) {
          if (whenError == null && attempts <= maxRetries) {
            await _delay(attempts);
            continue;
          }
          rethrow;
        }
        await _delay(attempts);
      }
    }
  }

  Future<void> _delay(int attempt) {
    return Future.delayed(strategy.getDelay(attempt));
  }
}
