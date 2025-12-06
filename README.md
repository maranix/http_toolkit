# HTTP Toolkit

A fully featured, composable HTTP client wrapper for Dart, adding missing "batteries" to the standard `http` package.

`http_toolkit` provides a powerful `Client` that supports **Interceptors**, **Middleware Pipelines**, and convenient **Extensions**, while remaining 100% compatible with the standard `http.BaseClient` interface.

## Features

- **🚀 Interceptors**: Modify requests, responses, and handle errors globally.
- **⛓️ Middleware Pipeline**: Compose behavior like authentication, logging, and retries.
- **🛠️ Built-in Middlewares**:
    - `RetryMiddleware`: Exponential backoff and customizable retry logic.
    - `LoggerMiddleware`: Debug requests and responses easily.
    - `BearerAuthMiddleware` & `BasicAuthMiddleware`: Simple authentication injection.
    - `HeadersMiddleware`: Global default headers.
- **⚡ Extensions**: Helper getters for `Response` (JSON decoding, status checks) and `Client` (query parameters).
- **🧘 Flexible**: Works with any `http.Client` implementation.

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  http_toolkit: ^1.0.0
```

## Usage

### Basic Usage

Use `http_toolkit.Client` as a drop-in replacement for `http.Client`.

```dart
import 'package:http_toolkit/http_toolkit.dart';

void main() async {
  final client = Client(
    middlewares: [
      LoggerMiddleware(),
      RetryMiddleware(maxRetries: 3),
    ],
  );

  final response = await client.get(Uri.parse('https://api.example.com/data'));
  
  if (response.isSuccess) {
    print(response.jsonMap); // Typed JSON access
  }
}
```

### Middlewares

Middlewares wrap the request execution. They run in the order defined.

```dart
final client = Client(
  middlewares: [
    // 1. Log the request
    LoggerMiddleware(logHeaders: true),
    
    // 2. Add Auth Token
    BearerAuthMiddleware('my-secret-token'),
    
    // 3. Retry if network fails or 503
    RetryMiddleware(
      maxRetries: 2,
### Middleware

Middleware allows you to intercept and modify requests and responses. You can create custom middleware by implementing the `Middleware` interface.

```dart
import 'package:http_toolkit/http_toolkit.dart';

class MyMiddleware implements Middleware {
  @override
  Future<StreamedResponse> handle(BaseRequest request, Handler next) async {
    print('Request: ${request.url}');
    final response = await next(request);
    print('Response: ${response.statusCode}');
    return response;
  }
}
```

### Built-in Middleware

`http_toolkit` comes with several built-in middlewares:

- **`RetryMiddleware`**: Retries failed requests with configurable backoff strategies.
  ```dart
  RetryMiddleware(
    maxRetries: 3,
    strategy: ExponentialBackoffStrategy(initialDelay: Duration(seconds: 1)),
  )
  ```
- **`LoggerMiddleware`**: Logs requests and responses to the console.
  ```dart
  LoggerMiddleware(logHeaders: true, logBody: true)
  ```
- **`BearerAuthMiddleware`**: Injects `Authorization: Bearer <token>` header.
- **`BasicAuthMiddleware`**: Injects `Authorization: Basic <credentials>` header.
- **`HeadersMiddleware`**: Adds default headers to every request.
- **`BaseUrlMiddleware`**: Prepends a base URL to request paths.

### Interceptors

Interceptors provide a lower-level hook for observing or modifying traffic without the full power of the middleware pipeline.

```dart
final client = Client(
  interceptors: [
    FunctionalInterceptor(
      onRequestCallback: (request) {
        // Modify request
        return request;
      },
    ),
  ],
);
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Extensions

Convenient extensions are available for `Response` and `Client`.

```dart
// JSON parsing
var data = response.json; // dynamic
var map = response.jsonMap; // Map<String, dynamic>
var list = response.jsonList; // List<dynamic>

// Status checks
if (response.isSuccess) { ... } // 200-299
if (response.isClientError) { ... } // 400-499
if (response.isServerError) { ... } // 500-599
```

## Contributing

Contributions are welcome! Please feel free to verify functionality and submit pull requests.
