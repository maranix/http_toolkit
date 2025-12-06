import 'package:http/http.dart';

/// A function that handles a request and returns a response.
typedef Handler = Future<StreamedResponse> Function(BaseRequest request);

/// A function that acts as a middleware.
///
/// It takes a [BaseRequest] and a [Handler] (the next middleware or the client),
/// and returns a [StreamedResponse].
typedef Middleware =
    Future<StreamedResponse> Function(
      BaseRequest request,
      Handler next,
    );

/// A helper to compose a list of [Middleware] into a single [Handler].
class Pipeline {
  final List<Middleware> _middlewares = [];

  Pipeline add(Middleware middleware) {
    _middlewares.add(middleware);
    return this;
  }

  Handler addHandler(Handler handler) {
    return (request) {
      Handler next = handler;
      for (var i = _middlewares.length - 1; i >= 0; i--) {
        final middleware = _middlewares[i];
        final currentNext = next;
        next = (request) => middleware(request, currentNext);
      }
      return next(request);
    };
  }
}
