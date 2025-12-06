import 'package:http/http.dart';
import '../middleware.dart';

/// Middleware that merges default headers into every request.
class HeadersMiddleware {
  const HeadersMiddleware({required this.headers});
  final Map<String, String> headers;

  Future<StreamedResponse> call(BaseRequest request, Handler next) {
    request.headers.addAll(headers);
    return next(request);
  }
}
