import 'dart:async';
import 'package:http/http.dart';

/// An interface for intercepting requests, responses, and errors.
abstract class Interceptor {
  /// Intercepts the request before it is sent.
  FutureOr<BaseRequest> onRequest(BaseRequest request);

  /// Intercepts the response before it is returned to the caller.
  FutureOr<BaseResponse> onResponse(BaseResponse response);

  /// Intercepts errors that occur during the request.
  FutureOr<BaseResponse> onError(Object error, StackTrace stackTrace);
}

/// A helper class to create an [Interceptor] from functions.
class FunctionalInterceptor implements Interceptor {
  const FunctionalInterceptor({
    this.onRequestCallback,
    this.onResponseCallback,
    this.onErrorCallback,
  });

  final FutureOr<BaseRequest> Function(BaseRequest)? onRequestCallback;
  final FutureOr<BaseResponse> Function(BaseResponse)? onResponseCallback;
  final FutureOr<BaseResponse> Function(Object, StackTrace)? onErrorCallback;

  @override
  FutureOr<BaseRequest> onRequest(BaseRequest request) {
    if (onRequestCallback != null) {
      return onRequestCallback!(request);
    }

    return request;
  }

  @override
  FutureOr<BaseResponse> onResponse(BaseResponse response) {
    if (onResponseCallback != null) {
      return onResponseCallback!(response);
    }

    return response;
  }

  @override
  FutureOr<BaseResponse> onError(Object error, StackTrace stackTrace) {
    if (onErrorCallback != null) {
      return onErrorCallback!(error, stackTrace);
    }

    if (error is Exception) {
      throw error;
    }

    throw Exception(
      'Expected `error` to be a subtype of `Exception` but got ${error.runtimeType}',
    );
  }
}
