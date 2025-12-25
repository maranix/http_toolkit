import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_toolkit/http_toolkit.dart';
import 'package:test/test.dart';

void main() {
  group('RetryMiddleware', () {
    group('basic retry behavior', () {
      test('retries on exception up to maxRetries', () async {
        var attempts = 0;
        final mockInner = MockClient((request) {
          attempts++;
          throw http.ClientException('Network Error');
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            const RetryMiddleware(
              maxRetries: 2,
              strategy: FixedDelayStrategy(Duration.zero),
            ),
          ],
        );

        try {
          await client.get(Uri.parse('https://example.com'));
        } on Exception catch (e) {
          expect(e, isA<http.ClientException>());
        }

        expect(attempts, 3); // 1 initial + 2 retries
      });

      test('stops retrying on success', () async {
        var attempts = 0;
        final mockInner = MockClient((request) async {
          attempts++;
          if (attempts < 2) {
            throw http.ClientException('Error');
          }

          return http.Response('ok', 200);
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            const RetryMiddleware(strategy: FixedDelayStrategy(Duration.zero)),
          ],
        );

        final response = await client.get(Uri.parse('https://example.com'));
        expect(response.statusCode, 200);
        expect(attempts, 2);
      });

      test('does not retry when maxRetries is 0', () async {
        var attempts = 0;
        final mockInner = MockClient((request) {
          attempts++;
          throw http.ClientException('Error');
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            const RetryMiddleware(
              maxRetries: 0,
              strategy: FixedDelayStrategy(Duration.zero),
            ),
          ],
        );

        try {
          await client.get(Uri.parse('https://example.com'));
        } on Exception catch (_) {}

        expect(attempts, 1);
      });

      test('returns immediately on first success', () async {
        var attempts = 0;
        final mockInner = MockClient((request) async {
          attempts++;
          return http.Response('ok', 200);
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            const RetryMiddleware(
              strategy: FixedDelayStrategy(Duration.zero),
            ),
          ],
        );

        final response = await client.get(Uri.parse('https://example.com'));
        expect(response.statusCode, 200);
        expect(attempts, 1);
      });
    });

    group('whenError callback', () {
      test('receives error, attempt count, and next delay', () async {
        final capturedParams = <Map<String, dynamic>>[];
        final mockInner = MockClient((request) {
          throw http.ClientException('Network Error');
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            RetryMiddleware(
              maxRetries: 2,
              strategy: const LinearBackoffStrategy(Duration(seconds: 1)),
              whenError: (error, attempt, nextDelay) {
                capturedParams.add({
                  'error': error,
                  'attempt': attempt,
                  'nextDelay': nextDelay,
                });
                return true;
              },
            ),
          ],
        );

        try {
          await client.get(Uri.parse('https://example.com'));
        } on Exception catch (_) {}

        // Callback is called for each attempt that will be retried.
        // After attempt 3 exceeds maxRetries (2), exception is rethrown without callback.
        expect(capturedParams.length, 2);

        // First attempt
        expect(capturedParams[0]['attempt'], 1);
        expect(capturedParams[0]['nextDelay'], const Duration(seconds: 1));
        expect(capturedParams[0]['error'], isA<http.ClientException>());

        // Second attempt
        expect(capturedParams[1]['attempt'], 2);
        expect(capturedParams[1]['nextDelay'], const Duration(seconds: 2));
      });

      test('stops retrying when whenError returns false', () async {
        var attempts = 0;
        final mockInner = MockClient((request) {
          attempts++;
          throw http.ClientException('Error');
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            RetryMiddleware(
              strategy: const FixedDelayStrategy(Duration.zero),
              whenError: (error, attempt, nextDelay) {
                return attempt < 2; // Only retry on first attempt
              },
            ),
          ],
        );

        try {
          await client.get(Uri.parse('https://example.com'));
        } on Exception catch (_) {}

        expect(attempts, 2); // Initial + 1 retry
      });

      test('can filter retries by error type', () async {
        var attempts = 0;
        final mockInner = MockClient((request) {
          attempts++;
          if (attempts == 1) {
            throw http.ClientException('Retryable');
          }
          throw const FormatException('Non-retryable');
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            RetryMiddleware(
              maxRetries: 5,
              strategy: const FixedDelayStrategy(Duration.zero),
              whenError: (error, attempt, nextDelay) {
                return error is http.ClientException;
              },
            ),
          ],
        );

        try {
          await client.get(Uri.parse('https://example.com'));
        } on Exception catch (e) {
          expect(e, isA<FormatException>());
        }

        expect(attempts, 2);
      });
    });

    group('whenResponse callback', () {
      test('receives response, attempt count, and delay duration', () async {
        final capturedParams = <Map<String, dynamic>>[];
        final mockInner = MockClient((request) async {
          return http.Response('error', 503);
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            RetryMiddleware(
              maxRetries: 2,
              strategy: const LinearBackoffStrategy(Duration(seconds: 1)),
              whenResponse: (response, attempt, elapsed) {
                capturedParams.add({
                  'statusCode': response.statusCode,
                  'attempt': attempt,
                  'elapsed': elapsed,
                });
                return response.statusCode >= 500;
              },
            ),
          ],
        );

        final response = await client.get(Uri.parse('https://example.com'));

        expect(response.statusCode, 503);
        // Callback is called for each attempt that will be retried.
        // After attempt 3 exceeds maxRetries (2), response is returned without callback.
        expect(capturedParams.length, 2);

        expect(capturedParams[0]['attempt'], 1);
        expect(capturedParams[0]['elapsed'], const Duration(seconds: 1));
        expect(capturedParams[0]['statusCode'], 503);

        expect(capturedParams[1]['attempt'], 2);
        expect(capturedParams[1]['elapsed'], const Duration(seconds: 2));
      });

      test('retries on 5xx responses when configured', () async {
        var attempts = 0;
        final mockInner = MockClient((request) async {
          attempts++;
          if (attempts < 3) {
            return http.Response('error', 503);
          }
          return http.Response('ok', 200);
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            RetryMiddleware(
              maxRetries: 5,
              strategy: const FixedDelayStrategy(Duration.zero),
              whenResponse: (response, attempt, elapsed) {
                return response.statusCode >= 500;
              },
            ),
          ],
        );

        final response = await client.get(Uri.parse('https://example.com'));

        expect(response.statusCode, 200);
        expect(attempts, 3);
      });

      test('does not retry on 4xx responses by default', () async {
        var attempts = 0;
        final mockInner = MockClient((request) async {
          attempts++;
          return http.Response('not found', 404);
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            RetryMiddleware(
              strategy: const FixedDelayStrategy(Duration.zero),
              whenResponse: (response, attempt, elapsed) {
                return response.statusCode >= 500; // Only retry 5xx
              },
            ),
          ],
        );

        final response = await client.get(Uri.parse('https://example.com'));

        expect(response.statusCode, 404);
        expect(attempts, 1);
      });

      test('stops retrying when whenResponse returns false', () async {
        var attempts = 0;
        final mockInner = MockClient((request) async {
          attempts++;
          return http.Response('rate limited', 429);
        });

        final client = Client(
          inner: mockInner,
          middlewares: [
            RetryMiddleware(
              maxRetries: 5,
              strategy: const FixedDelayStrategy(Duration.zero),
              whenResponse: (response, attempt, elapsed) {
                // Stop after 2 attempts for 429
                return response.statusCode == 429 && attempt < 2;
              },
            ),
          ],
        );

        final response = await client.get(Uri.parse('https://example.com'));

        expect(response.statusCode, 429);
        expect(attempts, 2);
      });
    });
  });

  group('BackoffStrategy', () {
    group('FixedDelayStrategy', () {
      test('returns same delay for all attempts', () {
        const strategy = FixedDelayStrategy(Duration(seconds: 2));

        expect(strategy.getDelayDuration(1), const Duration(seconds: 2));
        expect(strategy.getDelayDuration(2), const Duration(seconds: 2));
        expect(strategy.getDelayDuration(3), const Duration(seconds: 2));
        expect(strategy.getDelayDuration(10), const Duration(seconds: 2));
      });

      test('supports zero delay', () {
        const strategy = FixedDelayStrategy(Duration.zero);

        expect(strategy.getDelayDuration(1), Duration.zero);
        expect(strategy.getDelayDuration(5), Duration.zero);
      });
    });

    group('LinearBackoffStrategy', () {
      test('increases delay linearly with attempt count', () {
        const strategy = LinearBackoffStrategy(Duration(seconds: 1));

        expect(strategy.getDelayDuration(1), const Duration(seconds: 1));
        expect(strategy.getDelayDuration(2), const Duration(seconds: 2));
        expect(strategy.getDelayDuration(3), const Duration(seconds: 3));
        expect(strategy.getDelayDuration(5), const Duration(seconds: 5));
      });

      test('works with millisecond precision', () {
        const strategy = LinearBackoffStrategy(Duration(milliseconds: 100));

        expect(strategy.getDelayDuration(1), const Duration(milliseconds: 100));
        expect(strategy.getDelayDuration(3), const Duration(milliseconds: 300));
        expect(strategy.getDelayDuration(10), const Duration(seconds: 1));
      });
    });

    group('ExponentialBackoffStrategy', () {
      test('doubles delay with each attempt', () {
        const strategy = ExponentialBackoffStrategy();

        expect(strategy.getDelayDuration(1), const Duration(milliseconds: 500));
        expect(strategy.getDelayDuration(2), const Duration(seconds: 1));
        expect(strategy.getDelayDuration(3), const Duration(seconds: 2));
        expect(strategy.getDelayDuration(4), const Duration(seconds: 4));
        expect(strategy.getDelayDuration(5), const Duration(seconds: 8));
      });

      test('uses default initial delay of 500ms', () {
        const strategy = ExponentialBackoffStrategy();

        expect(strategy.getDelayDuration(1), const Duration(milliseconds: 500));
      });

      test('handles custom initial delay', () {
        const strategy = ExponentialBackoffStrategy(
          initialDelay: Duration(seconds: 1),
        );

        expect(strategy.getDelayDuration(1), const Duration(seconds: 1));
        expect(strategy.getDelayDuration(2), const Duration(seconds: 2));
        expect(strategy.getDelayDuration(3), const Duration(seconds: 4));
      });
    });
  });

  group('AuthMiddleware', () {
    test('BearerAuthMiddleware injects header', () async {
      final mockInner = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer mytoken');
        return http.Response('ok', 200);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [const BearerAuthMiddleware('mytoken')],
      );

      await client.get(Uri.parse('https://example.com'));
    });

    test('BasicAuthMiddleware injects header', () async {
      final mockInner = MockClient((request) async {
        // user:pass -> dXNlcjpwYXNz
        expect(request.headers['Authorization'], 'Basic dXNlcjpwYXNz');
        return http.Response('ok', 200);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [
          const BasicAuthMiddleware(username: 'user', password: 'pass'),
        ],
      );

      await client.get(Uri.parse('https://example.com'));
    });
  });

  group('BaseUrlMiddleware', () {
    test('retargets relative path to base url', () async {
      final mockInner = MockClient((request) async {
        expect(request.url.toString(), 'https://api.example.com/v1/users');
        return http.Response('ok', 200);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [
          BaseUrlMiddleware(Uri.parse('https://api.example.com/v1/')),
        ],
      );

      await client.get(Uri.parse('users'));
    });

    test('preserves query parameters', () async {
      final mockInner = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.example.com/v1/users?page=1',
        );
        return http.Response('ok', 200);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [
          BaseUrlMiddleware(Uri.parse('https://api.example.com/v1/')),
        ],
      );

      await client.get(Uri.parse('users?page=1'));
    });

    test('preserves fragment', () async {
      final mockInner = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.example.com/v1/users#top',
        );
        return http.Response('ok', 200);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [
          BaseUrlMiddleware(Uri.parse('https://api.example.com/v1/')),
        ],
      );

      await client.get(Uri.parse('users#top'));
    });
  });

  group('HeadersMiddleware', () {
    test('injects headers', () async {
      final mockInner = MockClient((request) async {
        expect(request.headers['X-Custom'], 'value');
        return http.Response('ok', 200);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [
          const HeadersMiddleware(headers: {'X-Custom': 'value'}),
        ],
      );

      await client.get(Uri.parse('https://example.com'));
    });

    test('overwrites existing headers if duplicated', () async {
      final mockInner = MockClient((request) async {
        expect(request.headers['X-Key'], 'new');
        return http.Response('ok', 200);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [
          const HeadersMiddleware(headers: {'X-Key': 'new'}),
        ],
      );

      await client.get(
        Uri.parse('https://example.com'),
        headers: {'X-Key': 'old'},
      );
    });
  });

  group('LoggerMiddleware', () {
    test('logs request and response', () async {
      final logOutput = <String>[];
      final logger = FunctionalLogger(
        logCallback: logOutput.add,
        logHeaders: true,
      );

      final mockInner = MockClient((request) async {
        return http.Response('ok', 200, request: request);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [LoggerMiddleware(logger: logger)],
      );

      await client.get(Uri.parse('https://example.com'));

      expect(
        logOutput,
        contains(
          'Request --> GET https://example.com',
        ),
      );
      expect(
        logOutput,
        contains(
          'Response <-- 200 https://example.com',
        ),
      );
    });

    test('logs body when enabled', () async {
      final logOutput = <String>[];
      final logger = FunctionalLogger(
        logCallback: logOutput.add,
        logBody: true,
      );

      final mockInner = MockClient((request) async {
        return http.Response('{"key": "value"}', 200);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [LoggerMiddleware(logger: logger, logBody: true)],
      );

      final response = await client.post(
        Uri.parse('https://example.com'),
        body: 'request-body',
      );

      expect(
        response.body,
        '{"key": "value"}',
      ); // Verify stream is still readable
      expect(logOutput, contains('Body: request-body'));
      expect(logOutput, contains('Body: {"key": "value"}'));
    });

    test('logs error on exception', () async {
      final logOutput = <String>[];
      final logger = FunctionalLogger(
        logCallback: logOutput.add,
      );

      final mockInner = MockClient((request) {
        throw http.ClientException('Fail');
      });

      final client = Client(
        inner: mockInner,
        middlewares: [LoggerMiddleware(logger: logger)],
      );

      try {
        await client.get(Uri.parse('https://example.com'));
      } on Exception catch (_) {}

      expect(
        logOutput.any((line) => line.startsWith('Error <--')),
        isTrue,
      );
    });
  });
}
