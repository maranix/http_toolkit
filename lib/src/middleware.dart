import 'package:http/http.dart';

/// A function that handles a request and returns a response.
typedef Handler = Future<StreamedResponse> Function(BaseRequest request);

/// The base class for all middlewares.
///
/// Middlewares are used to intercept and modify requests and responses.
/// They are executed in the order they are added to the client.
abstract interface class Middleware {
  const Middleware();

  /// Handles the request and calls [next] to proceed to the next middleware.
  Future<StreamedResponse> handle(BaseRequest request, Handler next);
}

/// A helper to compose a list of [Middleware] into a single [Handler].
class Pipeline {
  final List<Middleware> _middlewares = [];

  void add(Middleware middleware) {
    _middlewares.add(middleware);
  }

  void addAll(Iterable<Middleware> middlewares) {
    _middlewares.addAll(middlewares);
  }

  Handler addHandler(Handler handler) {
    return (request) {
      var next = handler;
      for (var i = _middlewares.length - 1; i >= 0; i--) {
        final middleware = _middlewares[i];
        final currentNext = next;
        next = (request) => middleware.handle(request, currentNext);
      }
      return next(request);
    };
  }
}
