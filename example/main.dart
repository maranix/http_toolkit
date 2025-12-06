// ignore_for_file: avoid_print

import 'package:http_toolkit/http_toolkit.dart';

void main() async {
  // 1. Create the client with middlewares and interceptors
  final client = Client(
    middlewares: [
      const LoggerMiddleware(logBody: true).call,
      const BearerAuthMiddleware('super-secret-token').call,
      const RetryMiddleware(
        maxRetries: 2,
      ).call, // Retry up to 2 times on failure
      const HeadersMiddleware(headers: {'User-Agent': 'HttpToolkit/1.0'}).call,
    ],
  );

  try {
    final response = await client.get(
      Uri.parse('https://jsonplaceholder.typicode.com/todos/1'),
    );

    if (response.isSuccess) {
      print('Status: ${response.statusCode}');
      print('Data: ${response.jsonMap}');
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
      Uri.parse('https://jsonplaceholder.typicode.com/invalid-endpoint'),
    );
    print('Status: ${response.statusCode}');
  } on Exception catch (e) {
    print('Error caught: $e');
  }

  client.close();
}
