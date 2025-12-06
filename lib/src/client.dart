import 'dart:async';
import 'package:http/http.dart' as http;
import 'interceptor.dart';
import 'middleware.dart';

/// A powerful HTTP client wrapper that supports interceptors and middleware.
class Client extends http.BaseClient {
  final http.Client _inner;
  final List<Interceptor> _interceptors;
  final List<Middleware> _middlewares;
  late final Handler _pipeline;

  Client({
    http.Client? inner,
    List<Interceptor>? interceptors,
    List<Middleware>? middlewares,
  }) : _inner = inner ?? http.Client(),
       _interceptors = interceptors ?? [],
       _middlewares = middlewares ?? [] {
    final pipeline = Pipeline();
    for (final middleware in _middlewares) {
      pipeline.add(middleware);
    }
    _pipeline = pipeline.addHandler(_inner.send);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    http.BaseRequest currentRequest = request;

    // 1. Run Request Interceptors
    for (final interceptor in _interceptors) {
      currentRequest = await interceptor.onRequest(currentRequest);
    }

    try {
      // 2. Run Middleware Pipeline (which calls inner.send at the end)
      final response = await _pipeline(currentRequest);

      // 3. Run Response Interceptors
      http.BaseResponse currentResponse = response;
      for (final interceptor in _interceptors) {
        currentResponse = await interceptor.onResponse(currentResponse);
      }

      // Ensure we return a StreamedResponse as expected by BaseClient.send
      if (currentResponse is http.StreamedResponse) {
        return currentResponse;
      } else {
        if (currentResponse is http.Response) {
          return http.StreamedResponse(
            http.ByteStream.fromBytes(currentResponse.bodyBytes),
            currentResponse.statusCode,
            contentLength: currentResponse.contentLength,
            request: currentResponse.request,
            headers: currentResponse.headers,
            isRedirect: currentResponse.isRedirect,
            persistentConnection: currentResponse.persistentConnection,
            reasonPhrase: currentResponse.reasonPhrase,
          );
        }

        return currentResponse as http.StreamedResponse;
      }
    } catch (e, stackTrace) {
      // 4. Run Error Interceptors
      try {
        // We need a way for onError to potentially resolve a Response or rethrow.
        // But `onError` returns `FutureOr<BaseResponse>`.
        // If it returns a response, we consider the error recovered.
        // If it throws, we bubble up.

        for (final interceptor in _interceptors) {
          try {
            return await interceptor.onError(e, stackTrace)
                as http.StreamedResponse;
          } catch (newError) {
            if (interceptor == _interceptors.last) rethrow;
            continue;
          }
        }
        rethrow;
      } catch (finalError) {
        rethrow;
      }
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
