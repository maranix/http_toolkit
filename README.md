# HTTP Toolkit

A fully featured, composable HTTP client wrapper for Dart, adding missing "batteries" to the standard `http` package.

`http_toolkit` provides a powerful `Client` that supports **Interceptors**, **Middleware Pipelines**, and convenient **Extensions**, while retaining maximum compatibility with the standard `http.BaseClient` interface.

## Features

- **🚀 Interceptors**: Modify requests, responses, and handle errors globally.
- **⛓️ Middleware Pipeline**: Compose behavior like authentication, logging, and retries.
- **🛠️ Built-in Middlewares**:
    - `RetryMiddleware`: Exponential backoff and customizable retry logic.
    - `LoggerMiddleware`: Debug requests and responses easily.
    - `BearerAuthMiddleware` & `BasicAuthMiddleware`: Simple authentication injection.
    - `HeadersMiddleware`: Global default headers.
- **⚡ Extensions**: Helper getters for `Response` (JSON decoding, status checks) and `Client` (typed JSON requests).
- **✅ ResponseValidator**: Reusable response validators for common HTTP patterns.
- **💪 Flexible**: Works with any `http.Client` implementation.

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  http_toolkit: ^2.0.0+1
```

## Usage

### Basic Usage

Use `http_toolkit.Client` as a drop-in replacement for `http.Client`.

```dart
import 'package:http_toolkit/http_toolkit.dart' as http_toolkit;

void main() async {
  final client = http_toolkit.Client(
    middlewares: [
      BaseUrlMiddleware(Uri.parse('https://api.example.com')),
      LoggerMiddleware(),
      RetryMiddleware(maxRetries: 3),
    ],
  );

  final response = await client.get(Uri.parse('/data'));
  
  if (response.isSuccess) {
    print(response.jsonMap()); // Typed JSON access
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
    RetryMiddleware(maxRetries: 2),
    ]
);
```

You can also create custom middleware by implementing the `Middleware` interface.

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
    // Observe retry attempts with new callback parameters
    whenError: (error, attempt, nextDelay) {
      print('Attempt $attempt failed, retrying in ${nextDelay.inSeconds}s');
      return true; // Return true to retry
    },
    whenResponse: (response, attempt, elapsed) {
      print('Got response on attempt $attempt after ${elapsed.inMilliseconds}ms');
      return response.statusCode >= 500; // Retry on server errors
    },
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

### Typed JSON Requests

Use `*Decoded` methods for type-safe JSON parsing with optional response validation:

```dart
// Define your model
class User {
  final int id;
  final String name;
  
  User({required this.id, required this.name});
  
  factory User.fromJson(Map<String, dynamic> json) {
      if (json case {
          'id': final int id,
          'name': final String name,
      }) {
          return User(id: id, name: name);
      }

      throw const FormatException("Malformed JSON body");
  }
}

// Fetch and parse in one step
final user = await client.getDecoded<User, Map<String, dynamic>>( // Types Mentioned Explicitly
  Uri.parse('https://api.example.com/user/1'),
  mapper: User.fromJson,
  responseValidator: ResponseValidator.success,
);

// Types can also be inferred from `mapper`.
// final user = await client.getDecoded( 
//   Uri.parse('https://api.example.com/user/1'),
//   mapper: User.fromJson,
//   responseValidator: ResponseValidator.success,
// );

```

Available methods:
- `getDecoded` - GET with JSON decoding
- `postDecoded` - POST with JSON decoding
- `putDecoded` - PUT with JSON decoding
- `patchDecoded` - PATCH with JSON decoding
- `deleteDecoded` - DELETE with JSON decoding

### Response Validators

Use `ResponseValidator` to validate responses before parsing:

```dart
// Validate successful response (200-299)
await client.getDecoded(
  uri,
  mapper: User.fromJson,
  responseValidator: ResponseValidator.success,
);

// Validate created (201)
await client.postDecoded(
  uri,
  body: jsonEncode(data),
  mapper: User.fromJson,
  responseValidator: ResponseValidator.created,
);

// Combine validators
await client.getDecoded(
  uri,
  mapper: User.fromJson,
  responseValidator: (response) {
    ResponseValidator.success(response);
    ResponseValidator.jsonContentType(response);
    ResponseValidator.notEmpty(response);
  },
);
```

Available validators:
- `ResponseValidator.success` - Status 200-299
- `ResponseValidator.created` - Status 201
- `ResponseValidator.successOrNoContent` - Status 200 or 204
- `ResponseValidator.statusCode(response, code)` - Specific status code
- `ResponseValidator.jsonContentType` - Content-Type is `application/json`
- `ResponseValidator.notEmpty` - Body is not empty

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

### Extensions

Convenient extensions are available for `Response` and `Client`.

```dart
// JSON parsing
var map = response.jsonMap(); // Map<String, dynamic>
var list = response.jsonList(); // List<dynamic>
var listOfInt = response.jsonList<int>(); // typed List<int>

// Status checks
if (response.isSuccess) { ... } // 200-299
if (response.isClientError) { ... } // 400-499
if (response.isServerError) { ... } // 500-599
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/maranix/http_toolkit/blob/main/LICENSE) file for details.
