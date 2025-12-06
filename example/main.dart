// ignore_for_file: avoid_print

import 'package:http_toolkit/http_toolkit.dart';

void main() async {
  // 1. Create the client with middlewares and interceptors
  final client = Client(
    middlewares: [
      BaseUrlMiddleware(
        Uri.parse('https://jsonplaceholder.typicode.com'),
      ),
      const LoggerMiddleware(logBody: true),
      const BearerAuthMiddleware('super-secret-token'),
      const RetryMiddleware(
        maxRetries: 2,
        strategy: FixedDelayStrategy(Duration(milliseconds: 200)),
      ),
      const HeadersMiddleware(headers: {'User-Agent': 'HttpToolkit/1.0'}),
    ],
  );

  try {
    final response = await client.get(
      Uri.parse('/todos/1'),
    );

    if (response.isSuccess) {
      print('Done');
    }
  } on Exception catch (e) {
    print('Error: $e');
  }

  try {
    // This should trigger retries if the host is reachable but returns 5xx,
    // or if connection fails (e.g. invalid host usually throws immediately, let's see)
    // jsonplaceholder doesn't have 5xx easily triggered, so this might just fail or 404.
    // 404 does NOT trigger retry in our default logic (only exceptions unless configured).
    final response = await client.get(
      Uri.parse('/invalid-endpoint'),
    );
    print('Status: ${response.statusCode}');
  } on Exception catch (e) {
    print('Error caught: $e');
  }

  client.close();
}
