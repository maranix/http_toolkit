// ignore_for_file: avoid_print

import 'package:http_toolkit/http_toolkit.dart';

void main() async {
  final client = Client(
    middlewares: [
      const LoggerMiddleware(logBody: true),
      const HeadersMiddleware(headers: {'User-Agent': 'HttpToolkit/1.0'}),
      RetryMiddleware(
        maxRetries: 2,
        strategy: const LinearBackoffStrategy(Duration(seconds: 1)),
        whenError: (err, attempts, nextTry) {
          print(
            'Got Error in attempt $attempts, Retrying in ${nextTry.inMilliseconds}ms...',
          );
          return true;
        },
        whenResponse: (res, attempts, totalDuration) {
          print(
            'Got Response in attempt $attempts, Recovered in total ${totalDuration.inMilliseconds}ms...',
          );
          return true;
        },
      ),
    ],
  );

  try {
    final response = await client.get(
      Uri.parse('http://localhost:8080'),
    );
    print('Status: ${response.statusCode}');
  } on Exception catch (e) {
    print('Error caught: $e');
  } finally {
    client.close();
  }
}
