import 'package:http/http.dart';
import 'package:http_toolkit/src/utils/request_copier.dart';
import '../middleware.dart';

/// A middleware that enforces a base URL for requests.
///
/// If the request URL scheme represents a relative path (or needs retargeting),
/// this middleware creates a new request pointing to the [baseUrl].
class BaseUrlMiddleware implements Middleware {
  const BaseUrlMiddleware(this.baseUrl);
  final Uri baseUrl;

  @override
  Future<StreamedResponse> handle(BaseRequest request, Handler next) {
    var newUrl = baseUrl.resolve(request.url.path);
    if (request.url.hasQuery) {
      newUrl = newUrl.replace(queryParameters: request.url.queryParameters);
    }
    if (request.url.hasFragment) {
      newUrl = newUrl.replace(fragment: request.url.fragment);
    }

    // We must copy the request to change the URL as BaseRequest.url is final.
    // copyRequest creates a copy with the SAME url, but we need to create a new instance manually.
    final retargetedRequest = copyRequest(request, url: newUrl);
    return next(retargetedRequest);
  }
}
