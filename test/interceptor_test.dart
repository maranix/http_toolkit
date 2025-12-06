import 'package:http_toolkit/http_toolkit.dart';
import 'package:test/test.dart';

void main() {
  group('FunctionalInterceptor', () {
    test('onRequest modifies request', () {
      final interceptor = FunctionalInterceptor(
        onRequestCallback: (request) {
          final newRequest = Request('POST', request.url);
          return newRequest;
        },
      );

      final request = Request('GET', Uri.parse('https://example.com'));
      final result = interceptor.onRequest(request);
      expect(result, isA<Request>());
      expect((result as Request).method, 'POST');
    });

    test('onRequest returns original request if callback is null', () {
      const interceptor = FunctionalInterceptor();
      final request = Request('GET', Uri.parse('https://example.com'));
      final result = interceptor.onRequest(request);
      expect(result, same(request));
    });

    test('onResponse modifies response', () {
      final interceptor = FunctionalInterceptor(
        onResponseCallback: (response) {
          return Response('modified', 201);
        },
      );

      final response = Response('original', 200);
      final result = interceptor.onResponse(response);
      expect(result, isA<Response>());
      expect((result as Response).body, 'modified');
      expect(result.statusCode, 201);
    });

    test('onResponse returns original response if callback is null', () {
      const interceptor = FunctionalInterceptor();
      final response = Response('original', 200);
      final result = interceptor.onResponse(response);
      expect(result, same(response));
    });

    test('onError handles error and returns response', () {
      final interceptor = FunctionalInterceptor(
        onErrorCallback: (error, stackTrace) {
          return Response('error handled', 500);
        },
      );

      final result = interceptor.onError(Exception('boom'), StackTrace.empty);
      expect(result, isA<Response>());
      expect((result as Response).body, 'error handled');
      expect(result.statusCode, 500);
    });

    test('onError rethrows exception if callback is null', () {
      const interceptor = FunctionalInterceptor();
      expect(
        () => interceptor.onError(Exception('boom'), StackTrace.empty),
        throwsException,
      );
    });

    test(
      'onError throws Exception if error is not Exception and callback is null',
      () {
        const interceptor = FunctionalInterceptor();
        expect(
          () => interceptor.onError('string error', StackTrace.empty),
          throwsException,
        );
      },
    );
  });
}
