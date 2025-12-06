import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_toolkit/http_toolkit.dart';
import 'package:test/test.dart';

void main() {
  group('RetryMiddleware', () {
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
