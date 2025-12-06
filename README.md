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
      whenResponse: (response) => response.statusCode == 503,
    ),
  ],
);
```

### Interceptors

Interceptors allow low-level access to the `Request` and `Response` objects before/after the middleware pipeline.

```dart
class MyInterceptor implements Interceptor {
  @override
  FutureOr<BaseRequest> onRequest(BaseRequest request) {
    print('Intercepted: ${request.url}');
    return request;
  }

  @override
  FutureOr<BaseResponse> onResponse(BaseResponse response) {
    return response;
  }

  @override
  FutureOr<BaseResponse> onError(Object error, StackTrace stackTrace) {
    throw error;
  }
}

final client = Client(interceptors: [MyInterceptor()]);
```

or use `FunctionalInterceptor` for quick tasks:

```dart
final client = Client(
  interceptors: [
    FunctionalInterceptor(
      onRequestCallback: (req) {
        req.headers['X-Custom-Header'] = '123';
        return req;
      },
    ),
  ],
);
```

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
