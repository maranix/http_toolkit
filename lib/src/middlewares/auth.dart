import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:http_toolkit/src/middleware.dart';

/// Middleware that injects a Bearer token into the Authorization header.
///
/// This is a [RequestMiddleware] because it only needs to set a header on the
/// request object before it is sent. It does not need to transform the request structure
/// or handle the response.
///
/// ## Example
///
/// ```dart
/// client = Client(
///   middlewares: [
///     const BearerAuthMiddleware('my-access-token'),
///   ],
/// );
/// ```
final class BearerAuthMiddleware implements RequestMiddleware {
  /// Creates a middleware that adds `Authorization: Bearer <token>`.
  const BearerAuthMiddleware(this.token);

  /// The raw token string (do not include "Bearer " prefix).
  final String token;

  @override
  void onRequest(http.BaseRequest request) {
    request.headers[io.HttpHeaders.authorizationHeader] = 'Bearer $token';
  }
}

/// Middleware that injects Basic Auth credentials into the Authorization header.
///
/// **Note:** credentials are encoded using [convert.base64Encode] in `username:password` format before injecting.
///
/// ## Example
///
/// ```dart
/// client = Client(
///   middlewares: [
///     const BasicAuthMiddleware(username: 'admin', password: 'password123'),
///   ],
/// );
/// ```
final class BasicAuthMiddleware implements RequestMiddleware {
  /// Creates a middleware that adds `Authorization: Basic <base64(user:pass)>`.
  const BasicAuthMiddleware({required this.username, required this.password});

  final String username;
  final String password;

  @override
  void onRequest(http.BaseRequest request) {
    final credentials = '$username:$password';
    final encoded = convert.base64Encode(convert.utf8.encode(credentials));

    request.headers[io.HttpHeaders.authorizationHeader] = 'Basic $encoded';
  }
}
