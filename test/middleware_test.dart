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
          RetryMiddleware(
            maxRetries: 2,
            delay: (_) => Duration.zero, // No delay for tests
          ).call,
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
          RetryMiddleware(delay: (_) => Duration.zero).call,
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
        middlewares: [const BearerAuthMiddleware('mytoken').call],
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
          const BasicAuthMiddleware(username: 'user', password: 'pass').call,
        ],
      );

      await client.get(Uri.parse('https://example.com'));
    });
  });
}
