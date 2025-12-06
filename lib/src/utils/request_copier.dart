import 'package:http/http.dart';

/// Copies a [BaseRequest] to allow re-sending or modification.
///
/// Supports [Request] and [MultipartRequest].
/// Throws [StateError] for unsupported types (like [StreamedRequest]).
BaseRequest copyRequest(BaseRequest request, {Uri? url}) {
  BaseRequest requestCopy;

  if (request is Request) {
    requestCopy = Request(request.method, url ?? request.url)
      ..encoding = request.encoding
      ..bodyBytes = request.bodyBytes;
  } else if (request is MultipartRequest) {
    requestCopy = MultipartRequest(request.method, url ?? request.url)
      ..fields.addAll(request.fields)
      ..files.addAll(request.files);
  } else if (request is StreamedRequest) {
    throw StateError('Cannot copy a StreamedRequest.');
  } else {
    throw StateError(
      'Unsupported request type for copy: ${request.runtimeType}',
    );
  }

  requestCopy
    ..headers.addAll(request.headers)
    ..followRedirects = request.followRedirects
    ..maxRedirects = request.maxRedirects
    ..persistentConnection = request.persistentConnection;

  return requestCopy;
}
