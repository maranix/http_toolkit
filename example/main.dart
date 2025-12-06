import 'package:http_toolkit/http_toolkit.dart';

void main() async {
  // 1. Create the client with middlewares and interceptors
  final client = Client(
    middlewares: [
      LoggerMiddleware(logHeaders: true, logBody: true),
      BearerAuthMiddleware('super-secret-token'),
      RetryMiddleware(maxRetries: 2), // Retry up to 2 times on failure
      HeadersMiddleware(headers: {'User-Agent': 'HttpToolkit/1.0'}),
    ],
  );

  print('--- Fetching Todos (Success Case) ---');
  try {
    final response = await client.get(
      Uri.parse('https://jsonplaceholder.typicode.com/todos/1'),
    );

    if (response.isSuccess) {
      print('Status: ${response.statusCode}');
      print('Data: ${response.jsonMap}');
    }
  } catch (e) {
    print('Error: $e');
  }

  print('\n--- Fetching Invalid URL (Error/Retry Case) ---');
  try {
    // This should trigger retries if the host is reachable but returns 5xx,
    // or if connection fails (e.g. invalid host usually throws immediately, let's see)
    // jsonplaceholder doesn't have 5xx easily triggered, so this might just fail or 404.
    // 404 does NOT trigger retry in our default logic (only exceptions unless configured).
    final response = await client.get(
      Uri.parse('https://jsonplaceholder.typicode.com/invalid-endpoint'),
    );
    print('Status: ${response.statusCode}');
  } catch (e) {
    print('Error caught: $e');
  }

  client.close();
}
