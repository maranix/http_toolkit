import 'dart:io' as io;

import 'package:http/http.dart' as http;

import 'package:http_toolkit/src/middleware.dart';

/// Logger interface for custom logging logic.
///
/// Implement this to direct logs to your own backend (e.g., Firebase Crashlytics,
/// Sentry, or a custom file logger).
abstract interface class LoggerInterface {
  /// Logs a request before it is sent.
  void logRequest(http.BaseRequest request);

  /// Logs a response after it is received, including the duration.
  void logResponse(http.BaseResponse response, Duration duration);

  /// Logs an error that occurred during the request.
  void logError(http.BaseRequest request, Object error, Duration duration);

  /// Cleans up any resources used by the logger.
  void dispose();
}

/// Default functional logger that writes to a callback or stdout.
class FunctionalLogger implements LoggerInterface {
  /// Creates a simple logger.
  ///
  /// [logCallback] can be provided to redirect output (e.g., to `print` or a specific log function).
  /// If null, defaults to `io.stdout.writeln`.
  FunctionalLogger({
    this.logCallback,
    this.logHeaders = false,
    this.logBody = false,
    this.headerFilter,
  });

  final void Function(String)? logCallback;
  final MapEntry<String, String> Function(MapEntry<String, String> entry)?
  headerFilter;
  final bool logHeaders;
  final bool logBody;

  final _buf = StringBuffer();

  void _log(String msg) {
    if (logCallback != null) {
      logCallback!(msg);
    } else {
      io.stdout.writeln(msg);
    }

    _buf.clear();
  }

  @override
  void logRequest(http.BaseRequest request) {
    _buf.writeln('Request --> ${request.method} ${request.url}');
    if (logHeaders) {
      _buf
        ..writeln()
        ..writeln('Headers:');

      // Make a copy so that we don't mutate the header in the request
      Iterable<MapEntry<String, String>> entries = List.from(
        request.headers.entries,
      );
      if (headerFilter != null) {
        entries = entries.map(headerFilter!);
      }

      for (final entry in entries) {
        _buf.writeln('\t${entry.key}: ${entry.value}');
      }
    }

    if (logBody) {
      if (request is http.Request) {
        _buf
          ..writeln()
          ..writeln('Body: ${request.body}');
      } else if (request is http.MultipartRequest) {
        _buf
          ..writeln()
          ..writeln('Body (Multipart):')
          ..writeln()
          ..writeln('\tFields:');

        for (final entry in request.fields.entries) {
          _buf.writeln('\t\t${entry.key}: ${entry.value}');
        }

        _buf
          ..writeln()
          ..writeln('\tFiles:');

        for (final file in request.files) {
          _buf.writeln('\t\t${file.field}: ${file.filename}');
        }
      } else {
        _buf
          ..writeln()
          ..writeln('Body: <StreamedRequest/Unknown>');
      }
    }

    _log(_buf.toString());
  }

  @override
  void logResponse(http.BaseResponse response, Duration duration) {
    final ms = duration.inMilliseconds;

    _buf
      ..writeln()
      ..writeln(
        'Response <-- ${response.statusCode} ${response.request?.url} '
        '(${ms}ms)',
      );

    if (logHeaders) {
      _buf
        ..writeln()
        ..writeln('Headers:');

      for (final entry in response.headers.entries) {
        _buf.writeln('\t${entry.key}: ${entry.value}');
      }
    }

    if (logBody) {
      if (response is http.Response) {
        _buf
          ..writeln()
          ..writeln('Body: ${response.body}');
      } else {
        _buf
          ..writeln()
          ..writeln('Body: <StreamedResponse/Unknown>');
      }
    }

    _log(_buf.toString());
  }

  @override
  void logError(http.BaseRequest request, Object error, Duration duration) {
    _buf
      ..writeln()
      ..writeln(
        'Error <-- ${request.url} (${duration.inMilliseconds}ms):',
      )
      ..writeln(error);

    _log(_buf.toString());
  }

  @override
  void dispose() {
    _buf.clear();
  }
}

/// Logger middleware that measures request duration and logs request/response/errors.
///
/// This is an [AsyncMiddleware] because it needs to measure the time taken
/// by the `next` handler and intercept any errors.
class LoggerMiddleware implements AsyncMiddleware {
  /// Creates a logger middleware.
  ///
  /// [logger] allows injecting a custom [LoggerInterface]. Defaults to [FunctionalLogger].
  LoggerMiddleware({
    LoggerInterface? logger,
    this.logRequest = true,
    this.logResponse = true,
    this.logError = true,
    this.logStreamedResponseBody = false,
  }) : _logger = logger ?? FunctionalLogger();

  final LoggerInterface _logger;

  final bool logRequest;
  final bool logResponse;
  final bool logError;

  /// **WARNING:** Enabling streamed body logging intercepts the response stream.
  /// This is intended for debugging only.
  ///
  /// It introduces significant latency, performance overhead, and memory
  /// consumption because the stream must be read into memory and re-emitted.
  final bool logStreamedResponseBody;

  @override
  Future<http.StreamedResponse> handle(
    http.BaseRequest request,
    RequestHandler next,
  ) async {
    if (logRequest) {
      _logger.logRequest(request);
    }

    final stopwatch = Stopwatch()..start();

    try {
      final response = await next(request);

      stopwatch.stop();

      if (!logResponse) {
        return response;
      }

      // Log response safely. StreamedResponse bodies are not consumed.
      if (!logStreamedResponseBody) {
        _logger.logResponse(response, stopwatch.elapsed);
        return response;
      }

      // Need to consume & convert the response body stream to log it.
      final bytes = await response.stream.toBytes();
      final res = http.Response.bytes(
        bytes,
        response.statusCode,
        request: request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );

      _logger.logResponse(res, stopwatch.elapsed);

      // Return a new StreamedResponse from the bytes we read.
      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        res.statusCode,
        contentLength: res.contentLength,
        request: res.request,
        headers: res.headers,
        isRedirect: res.isRedirect,
        persistentConnection: res.persistentConnection,
        reasonPhrase: res.reasonPhrase,
      );
    } catch (e) {
      stopwatch.stop();

      if (logError) {
        _logger.logError(request, e, stopwatch.elapsed);
      }

      rethrow;
    } finally {
      stopwatch.stop();
      _logger.dispose();
    }
  }
}
