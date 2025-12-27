import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_toolkit/http_toolkit.dart';
import 'package:test/test.dart';

// Helper for testing inline middlewares
class FunctionalMiddleware implements AsyncMiddleware {
  const FunctionalMiddleware(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest, RequestHandler)
  handler;

  @override
  Future<http.StreamedResponse> handle(
    http.BaseRequest request,
    RequestHandler next,
  ) {
    return handler(request, next);
  }
}

void main() {
  group('Client', () {
    test('executes middleware pipeline', () async {
      final mockInner = MockClient((request) async {
        return http.Response('ok', 200);
      });

      var middlewareCalled = false;
      final middleware = FunctionalMiddleware((request, next) {
        middlewareCalled = true;
        return next(request);
      });

      final client = Client(inner: mockInner, middlewares: [middleware]);
      await client.get(Uri.parse('https://example.com'));

      expect(middlewareCalled, isTrue);
    });

    test('middleware can modify request headers', () async {
      final mockInner = MockClient((request) async {
        expect(request.headers['X-Custom'], 'FoundIt');
        return http.Response('ok', 200);
      });

      final middleware = FunctionalMiddleware((request, next) {
        request.headers['X-Custom'] = 'FoundIt';
        return next(request);
      });

      final client = Client(inner: mockInner, middlewares: [middleware]);
      await client.get(Uri.parse('https://example.com'));
    });
  });
}
