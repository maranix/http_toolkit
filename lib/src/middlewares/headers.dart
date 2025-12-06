import 'package:http/http.dart';
import '../middleware.dart';

/// Middleware that merges default headers into every request.
class HeadersMiddleware implements Middleware {
  const HeadersMiddleware({required this.headers});
  final Map<String, String> headers;

  @override
  Future<StreamedResponse> handle(BaseRequest request, Handler next) {
    request.headers.addAll(headers);
    return next(request);
  }
}
