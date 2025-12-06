import 'package:http/http.dart';
import '../middleware.dart';

/// A middleware that logs requests and responses.
class LoggerMiddleware {
  final void Function(String message)? logger;
  final bool logHeaders;
  final bool logBody;

  const LoggerMiddleware({
    this.logger,
    this.logHeaders = false,
    this.logBody = false,
  });

  void _log(String message) {
    if (logger != null) {
      logger!(message);
    } else {
      // ignore: avoid_print
      print(message);
    }
  }

  Future<StreamedResponse> call(BaseRequest request, Handler next) async {
    _log('--> ${request.method} ${request.url}');
    if (logHeaders) {
      request.headers.forEach((k, v) => _log('$k: $v'));
    }
    if (logBody && request is Request) {
      _log('Body: ${request.body}');
    }

    try {
      final response = await next(request);
      _log('<-- ${response.statusCode} ${request.url}');
      if (logHeaders) {
        response.headers.forEach((k, v) => _log('$k: $v'));
      }
      return response;
    } catch (e) {
      _log('<-- ERROR ${request.url}: $e');
      rethrow;
    }
  }
}
