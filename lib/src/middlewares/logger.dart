import 'dart:io' as io;

import 'package:http/http.dart';
import '../middleware.dart';

/// An interface for custom logging logic.
abstract interface class LoggerInterface {
  void logRequest(BaseRequest request);
  void logResponse(BaseResponse response);
  void logError(BaseRequest request, Object error);
}

/// A simplified functional logger.
class FunctionalLogger implements LoggerInterface {
  const FunctionalLogger({
    this.logCallback,
    this.logHeaders = false,
    this.logBody = false,
  });

  final void Function(String)? logCallback;
  final bool logHeaders;
  final bool logBody;

  void _log(String msg) {
    if (logCallback != null) {
      logCallback!(msg);
    } else {
      io.stdout.writeln(msg);
    }
  }

  @override
  void logRequest(BaseRequest request) {
    _log('Request --> ${request.method} ${request.url}');
    if (logHeaders) {
      _log('Headers:');
      request.headers.forEach((k, v) => _log('  $k: $v'));
    }
    if (logBody) {
      if (request is Request) {
        _log('Body: ${request.body}');
      } else if (request is MultipartRequest) {
        _log(
          'Body (Multipart): Fields=${request.fields.keys.toList()} Files=${request.files.map((f) => f.field).toList()}',
        );
      }
    }
  }

  @override
  void logResponse(BaseResponse response) {
    _log('Response <-- ${response.statusCode} ${response.request?.url}');
    if (logHeaders) {
      _log('Headers:');
      response.headers.forEach((k, v) => _log('  $k: $v'));
    }
    if (logBody) {
      if (response is Response) {
        _log('Body: ${response.body}');
      } else {
        _log('Body: <StreamedResponse/Unknown>');
      }
    }
  }

  @override
  void logError(BaseRequest request, Object error) {
    _log('Error <-- ${request.url}: $error');
  }
}

/// A middleware that logs requests and responses.
class LoggerMiddleware implements Middleware {
  const LoggerMiddleware({
    this.logger,
    this.logHeaders = false,
    this.logBody = false,
  });

  final LoggerInterface? logger;
  final bool logHeaders;
  final bool logBody;

  LoggerInterface get _logger =>
      logger ?? FunctionalLogger(logHeaders: logHeaders, logBody: logBody);

  @override
  Future<StreamedResponse> handle(BaseRequest request, Handler next) async {
    _logger.logRequest(request);

    try {
      final response = await next(request);

      if (logBody) {
        final bytes = await response.stream.toBytes();
        final bufferedResponse = Response.bytes(
          bytes,
          response.statusCode,
          request: response.request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );

        _logger.logResponse(bufferedResponse);

        // Return a new StreamedResponse from the bytes we read.
        return StreamedResponse(
          ByteStream.fromBytes(bytes),
          bufferedResponse.statusCode,
          contentLength: bufferedResponse.contentLength,
          request: bufferedResponse.request,
          headers: bufferedResponse.headers,
          isRedirect: bufferedResponse.isRedirect,
          persistentConnection: bufferedResponse.persistentConnection,
          reasonPhrase: bufferedResponse.reasonPhrase,
        );
      } else {
        _logger.logResponse(response);
        return response;
      }
    } catch (e) {
      _logger.logError(request, e);
      rethrow;
    }
  }
}
