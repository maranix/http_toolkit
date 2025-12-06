import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_toolkit/http_toolkit.dart';
import 'package:test/test.dart';

void main() {
  group('Client', () {
    test('executes request interceptors', () async {
      final mockInner = MockClient((request) async {
        return http.Response('ok', 200);
      });

      var interceptorCalled = false;
      final interceptor = FunctionalInterceptor(
        onRequestCallback: (request) {
          interceptorCalled = true;
          return request;
        },
      );

      final client = Client(inner: mockInner, interceptors: [interceptor]);
      await client.get(Uri.parse('https://example.com'));

      expect(interceptorCalled, isTrue);
    });

    test('executes response interceptors', () async {
      final mockInner = MockClient((request) async {
        return http.Response('ok', 200);
      });

      var interceptorCalled = false;
      final interceptor = FunctionalInterceptor(
        onResponseCallback: (response) {
          interceptorCalled = true;
          return response;
        },
      );

      final client = Client(inner: mockInner, interceptors: [interceptor]);
      await client.get(Uri.parse('https://example.com'));

      expect(interceptorCalled, isTrue);
    });

    test('executes middleware pipeline', () async {
      final mockInner = MockClient((request) async {
        return http.Response('ok', 200);
      });

      var middlewareCalled = false;
      Future<http.StreamedResponse> middleware(
        http.BaseRequest request,
        Handler next,
      ) {
        middlewareCalled = true;
        return next(request);
      }

      final client = Client(inner: mockInner, middlewares: [middleware]);
      await client.get(Uri.parse('https://example.com'));

      expect(middlewareCalled, isTrue);
    });

    test('middleware can modify request headers', () async {
      final mockInner = MockClient((request) async {
        expect(request.headers['X-Custom'], 'FoundIt');
        return http.Response('ok', 200);
      });

      Future<http.StreamedResponse> middleware(
        http.BaseRequest request,
        Handler next,
      ) {
        request.headers['X-Custom'] = 'FoundIt';
        return next(request);
      }

      final client = Client(inner: mockInner, middlewares: [middleware]);
      await client.get(Uri.parse('https://example.com'));
    });
  });
}
