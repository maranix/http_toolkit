import 'dart:convert';
import 'package:http/http.dart';

extension ResponseExtensions on Response {
  /// Decodes the body of the response as JSON.
  dynamic get json {
    return jsonDecode(body);
  }

  /// Decodes the body of the response as a Map.
  /// Throws if the decoded JSON is not a Map.
  Map<String, dynamic> get jsonMap {
    final decoded = json;
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Response body is not a JSON Map.');
  }

  /// Decodes the body of the response as a List.
  /// Throws if the decoded JSON is not a List.
  List<dynamic> get jsonList {
    final decoded = json;
    if (decoded is List) {
      return decoded;
    }
    throw const FormatException('Response body is not a JSON List.');
  }

  /// Returns `true` if the status code is between 200 and 299.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Returns `true` if the status code is between 300 and 399.
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  /// Returns `true` if the status code is between 400 and 499.
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Returns `true` if the status code is between 500 and 599.
  bool get isServerError => statusCode >= 500 && statusCode < 600;
}

extension ClientExtensions on Client {
  /// Sends an HTTP GET request with the given headers and [queryParameters].
  ///
  /// If [queryParameters] is provided, it is added to the [url].
  Future<Response> get(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    var updatedUrl = url;
    if (queryParameters != null && queryParameters.isNotEmpty) {
      updatedUrl = url.replace(
        queryParameters: {...url.queryParameters, ...queryParameters},
      );
    }

    return this.get(updatedUrl, headers: headers);
  }
}
