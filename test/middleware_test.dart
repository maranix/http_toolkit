import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_toolkit/http_toolkit.dart';

void main() {
  group('RetryMiddleware', () {
    test('retries on exception up to maxRetries', () async {
      int attempts = 0;
      final mockInner = MockClient((request) async {
        attempts++;
        throw http.ClientException('Network Error');
      });

      final client = Client(
        inner: mockInner,
        middlewares: [
          RetryMiddleware(
            maxRetries: 2,
            delay: (_) => Duration.zero, // No delay for tests
          ),
        ],
      );

      try {
        await client.get(Uri.parse('https://example.com'));
      } catch (e) {
        expect(e, isA<http.ClientException>());
      }

      expect(attempts, 3); // 1 initial + 2 retries
    });

    test('stops retrying on success', () async {
      int attempts = 0;
      final mockInner = MockClient((request) async {
        attempts++;
        if (attempts < 2) throw http.ClientException('Error');
        return http.Response('ok', 200);
      });

      final client = Client(
        inner: mockInner,
        middlewares: [
          RetryMiddleware(maxRetries: 3, delay: (_) => Duration.zero),
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
        middlewares: [BearerAuthMiddleware('mytoken')],
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
        middlewares: [BasicAuthMiddleware(username: 'user', password: 'pass')],
      );

      await client.get(Uri.parse('https://example.com'));
    });
  });
}
