// ignore_for_file: avoid_print

import 'package:http_toolkit/http_toolkit.dart';

void main() async {
  final client = Client(
    middlewares: [
      LoggerMiddleware(
        logger: FunctionalLogger(logBody: true, logHeaders: true),
        logStreamedResponseBody: true,
      ),
      const BaseUrlMiddleware('https://jsonplaceholder.typicode.com'),
      const BearerAuthMiddleware('super-secret-token'),
      const RetryMiddleware(
        maxRetries: 2,
        strategy: .fixed(Duration(milliseconds: 200)),
      ),
      const HeadersMiddleware(headers: {'User-Agent': 'HttpToolkit/1.0'}),
    ],
  );

  try {
    final response = await client.get(Uri.parse('/todos/1'));

    if (response.isSuccess) {
      print('Done');
    }
  } on Exception catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
