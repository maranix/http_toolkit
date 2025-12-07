import 'dart:async';
import 'dart:math';
import 'package:http/http.dart';
import '../middleware.dart';
import '../utils/request_copier.dart';

/// A strategy for calculating the delay before the next retry.
abstract interface class BackoffStrategy {
  const BackoffStrategy();

  Duration getDelayDuration(int attempt);
}

/// A strategy that waits for a fixed duration.
class FixedDelayStrategy implements BackoffStrategy {
  const FixedDelayStrategy(this.delay);
  final Duration delay;

  @override
  Duration getDelayDuration(int attempt) => delay;
}

/// A strategy that waits for a duration that increases linearly with the attempt count.
class LinearBackoffStrategy implements BackoffStrategy {
  const LinearBackoffStrategy(this.initialDelay);
  final Duration initialDelay;

  @override
  Duration getDelayDuration(int attempt) => initialDelay * attempt;
}

/// A strategy that waits for a duration that increases exponentially with the attempt count.
class ExponentialBackoffStrategy implements BackoffStrategy {
  const ExponentialBackoffStrategy({
    this.initialDelay = const Duration(milliseconds: 500),
  });
  final Duration initialDelay;

  @override
  Duration getDelayDuration(int attempt) {
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
  final bool Function(Object error, int attempt, Duration nextAttempt)?
  whenError;
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
