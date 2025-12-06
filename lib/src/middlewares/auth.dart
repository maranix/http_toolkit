import 'dart:convert';
import 'package:http/http.dart';
import '../middleware.dart';

/// Middleware that injects a Bearer token into the Authorization header.
class BearerAuthMiddleware {
  const BearerAuthMiddleware(this.token);
  final String token;

  Future<StreamedResponse> call(BaseRequest request, Handler next) {
    request.headers['Authorization'] = 'Bearer $token';
    return next(request);
  }
}

/// Middleware that injects Basic Auth credentials into the Authorization header.
class BasicAuthMiddleware {
  const BasicAuthMiddleware({required this.username, required this.password});
  final String username;
  final String password;

  Future<StreamedResponse> call(BaseRequest request, Handler next) {
    final credentials = '$username:$password';
    final encoded = base64Encode(utf8.encode(credentials));
    request.headers['Authorization'] = 'Basic $encoded';
    return next(request);
  }
}
