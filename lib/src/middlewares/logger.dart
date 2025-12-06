import 'dart:developer' as dev;

import 'package:http/http.dart';
import '../middleware.dart';

/// A middleware that logs requests and responses.
class LoggerMiddleware {
  const LoggerMiddleware({
    this.logger,
    this.logHeaders = false,
    this.logBody = false,
  });

  final void Function({BaseRequest? reqLogger, BaseResponse? resLogger})?
  logger;
  final bool logHeaders;
  final bool logBody;

  void _defaultLog(String message) {
    dev.log(message);
  }

  Future<StreamedResponse> call(BaseRequest request, Handler next) async {
    if (logger != null) {
      logger!(reqLogger: request);
    } else {
      _defaultLog('--> ${request.method} ${request.url}');
      if (logHeaders) {
        request.headers.forEach((k, v) => _defaultLog('$k: $v'));
      }

      if (logBody && request is Request) {
        _defaultLog('Body: ${request.body}');
      }
    }

    try {
      final response = await next(request);
      _defaultLog('<-- ${response.statusCode} ${request.url}');
      if (logHeaders) {
        response.headers.forEach((k, v) => _defaultLog('$k: $v'));
      }

      return response;
    } catch (e) {
      _defaultLog('<-- ERROR ${request.url}: $e');
      rethrow;
    }
  }
}
