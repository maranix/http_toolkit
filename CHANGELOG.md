# Changelog

## 3.0.0

A major release focused on architectural cleanup, performance improvements, reduced overhead and improved Developer Experience.

### Breaking Changes

- **Interceptors Removed**: The `Interceptors` API has been completely removed in favor of the new `Middleware` pipeline.
    - Use `RequestMiddleware` for synchronous side effects.
    - Use `RequestTransformerMiddleware` for modifying requests.
    - Use `ResponseMiddleware` for processing responses.
    - Use `AsyncMiddleware` for wrapping request lifecycles.

### New Features

    - **CloneRequestX**: A safe `clone` and `cloneWith` extension for `http.BaseRequest` to allow middlewares to have complete control over requests by creating copies.
    - **RetryMiddleware**: Now supports `dot shorthands` for easier initialization in Dart 3.10+.
    - **LoggerMiddleware**: Based on `AsyncMiddleware`, now more composeable and provides more granular control on logging capabilities.

### 🚀 Improvements

- **Documentation**: Complete rewrite of the library documentation, README, and examples.
- **Architecture**: The `Middleware` system is now strictly typed and composed using an "Onion Architecture", ensuring predictable execution order.
- **Performance**: The handler is now composed during `Client` initialization and reduces the overall overhead of processing over middlewares on each request and response thus providing significant performance uplift.

## 2.0.0+1

- Minor documentation updates.

## 2.0.0

### Breaking Changes

- **RetryMiddleware**:
    - `whenError` callback now receives `(Object error, int attempt, Duration nextAttempt)`.
    - `whenResponse` callback now receives `(BaseResponse response, int attempt, Duration totalDuration)`.
    - `BackoffStrategy.getDelay` renamed to `getDelayDuration`.
    - `BackoffStrategy` is now an interface rather than a typedef.
- **Client Extensions**: `getWith` has been removed. Use `getDecoded` instead.

### New Features

- **Safe JSON Extensions**: New `*Decoded` methods on `Client` (`getDecoded`, `postDecoded`, `putDecoded`, `patchDecoded`, `deleteDecoded`) that handle:
    - JSON decoding
    - Type casting (safe mapping to your models)
    - Response validation
- **ResponseValidator**: A utility class for validating standard HTTP responses:
    - `ResponseValidator.success` (200-299)
    - `ResponseValidator.created` (201)
    - `ResponseValidator.jsonContentType` (application/json)
- **Types**: New `types.dart` exports `ResponseBodyMapper<R, T>` and `ResponseValidatorCallback`.

## 1.0.0+1

- Minor fixes and updates to docs.

## 1.0.0

- Initial release.
