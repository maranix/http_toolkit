/// @docImport 'package:http_toolkit/http_toolkit.dart';
///
/// A powerful, composable HTTP client wrapper for Dart.
///
/// `http_toolkit` provides a robust "missing battery" layer for the standard `http` package,
/// enabling advanced features like **Middleware Pipelines** and **Type-safe Extensions**
/// while maintaining maximum compatibility with `http.BaseClient`.
///
/// ## 🏗️ Architecture
///
/// The core of `http_toolkit` is the [Client], which wraps a standard `http.Client`
/// and executes a pipeline of [Middleware]. This pipeline implements a layered
/// "Onion Architecture", where requests traverse through layers of middleware
/// before reaching the network, and responses traverse back out.
///
/// ### Class Relationships
///
/// ```mermaid
/// classDiagram
///     Client *-- Middleware : has many
///     Client --|> BaseClient : extends
///     <<interface>> Middleware
///     Middleware <|.. AsyncMiddleware
///     Middleware <|.. RequestMiddleware
///     Middleware <|.. RequestTransformerMiddleware
///     Middleware <|.. ResponseMiddleware
///
///     class Client {
///         +List~Middleware~ middlewares
///         +send(BaseRequest) StreamedResponse
///     }
///
///     class AsyncMiddleware {
///         +handle(request, next) StreamedResponse
///     }
///
///     class RequestMiddleware {
///         +onRequest(BaseRequest) void
///     }
/// ```
///
/// ### Request & Response Flow
///
/// Use this diagram to understand how data flows through the system.
///
/// ```mermaid
/// sequenceDiagram
///     participant User
///     participant Client
///     participant Async as Async Middleware
///     participant Req as Request Middleware
///     participant Trans as Transformer
///     participant Net as Network (http.Client)
///
///     User->>Client: client.send(request)
///     Client->>Async: handle(request, next)
///     note right of Async: Starts timer / Prep
///     Async->>Req: onRequest(request)
///     note right of Req: Log "Start", update metrics
///     Async->>Trans: onRequest(request)
///     note right of Trans: Add Auth, resolve URL
///     Trans-->>Net: transformedRequest
///     Net-->>Trans: response
///     Trans-->>Req: response
///     Req-->>Async: response
///     note right of Async: Stop timer / Error check
///     Async-->>User: response
/// ```
///
/// ### 🔄 Middleware Precedence
///
/// Understanding execution order is critical for composing behaviors correctly.
///
/// | Middleware Type | Order | Behavior | Best Use Case |
/// | :--- | :--- | :--- | :--- |
/// | **Async** | **LIFO** (Outer) | Wraps entire call | Retries, Error Handling, Response Timing |
/// | **Request** | **FIFO** (Inner) | Side-effect only | Logging, Metrics, Analytics |
/// | **Transformer** | **LIFO** (Inner) | Modifies request | Authentication, Base URL, Header injection |
/// | **Response** | **LIFO** (Inner) | Modifies response | Global Validation, Error mapping |
///
/// ## 🧩 Built-in Middlewares
///
/// *   [RetryMiddleware]: Automatically retries failed requests with customizable backoff strategies.
/// *   [LoggerMiddleware]: Comprehensive logging of requests, responses, and errors.
/// *   [BearerAuthMiddleware] / [BasicAuthMiddleware]: Simple authentication injection.
/// *   [HeadersMiddleware]: Applies default headers to every request.
/// *   [BaseUrlMiddleware]: Resolves relative paths against a base URL.
///
/// ## 🚀 Usage Example
///
/// ```dart
/// import 'package:http_toolkit/http_toolkit.dart';
///
/// void main() async {
///   final client = Client(
///     middlewares: [
///       // 1. (Outer) Wrap everything in logging and retries
///       LoggerMiddleware(logBody: true),
///
///       const RetryMiddleware(
///         maxRetries: 3,
///         strategy: BackoffStrategy.exponential(),
///       ),
///
///       // 2. (Inner) Modify request before sending
///       const BearerAuthMiddleware('my-token'),
///       const BaseUrlMiddleware('https://api.example.com'),
///     ],
///   );
///
///   // Request is: GET https://api.example.com/users/1
///   // With headers: Authorization: Bearer my-token
///   final user = await client.getDecoded<User, Map<String, dynamic>>(
///     Uri.parse('/users/1'),
///     mapper: User.fromJson,
///   );
/// }
/// ```
library;

export 'package:http/http.dart'
    hide Client; // Export http package for convenience as requested

export 'src/client.dart';
export 'src/extension.dart';
export 'src/middleware.dart';
export 'src/middlewares/auth.dart';
export 'src/middlewares/base_url.dart';
export 'src/middlewares/headers.dart';
export 'src/middlewares/logger.dart';
export 'src/middlewares/retry.dart';
export 'src/validator.dart';
