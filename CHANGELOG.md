# Changelog

## 3.0.0

A major release focused on architectural cleanup, type safety, and developer experience.

### 💥 Breaking Changes

- **Interceptors Removed**: The `Interceptors` API has been completely removed in favor of the new `Middleware` pipeline.
    - Use `RequestMiddleware` for synchronous side effects.
    - Use `RequestTransformerMiddleware` for modifying requests.
    - Use `ResponseMiddleware` for processing responses.
    - Use `AsyncMiddleware` for wrapping request lifecycles.
- **RetryMiddleware**:
    - `whenError` callback now receives `(Object error, int attempt, Duration nextAttempt)`.
    - `whenResponse` callback now receives `(BaseResponse response, int attempt, Duration totalDuration)`.
    - `BackoffStrategy.getDelay` renamed to `getDelayDuration`.
    - `BackoffStrategy` is now an interface rather than a typedef.
- **Client Extensions**: `getWith` has been removed. Use `getDecoded` instead.

### ✨ New Features

- **Safe JSON Extensions**: New `*Decoded` methods on `Client` (`getDecoded`, `postDecoded`, `putDecoded`, `patchDecoded`, `deleteDecoded`) that handle:
    - JSON decoding
    - Type casting (safe mapping to your models)
    - Response validation
- **ResponseValidator**: A utility class for validating standard HTTP responses:
    - `ResponseValidator.success` (200-299)
    - `ResponseValidator.created` (201)
    - `ResponseValidator.jsonContentType` (application/json)
- **CloneRequestX**: A safe `clone()` extension for `http.BaseRequest` to allow middlewares to "mutate" requests by creating copies.
- **Types**: New `types.dart` exports `ResponseBodyMapper<R, T>` and `ResponseValidatorCallback`.

### 🚀 Improvements

- **Documentation**: Complete rewrite of the library documentation, README, and examples.
- **Architecture**: The `Middleware` system is now strictly typed and composed using an "Onion Architecture", ensuring predictable execution order.
- **Logging**: `LoggerMiddleware` now supports a generic `LoggerInterface` for integrating with any logging system.

## 2.0.0+1

- Minor documentation updates.

## 2.0.0

### Breaking Changes

- **Task Group API**: `TaskGroup` now supports generic `Label` and `Tags` types for better type safety.
- **Task Execution**: `Task.run` and `Task.watch` now enforce type matching for return values.

### New Features

- **Generic Tasks**: Tasks can now return typed results.
- **Task Caching**: Improved caching mechanism for tasks with identical keys.

## 1.0.0+1

- Minor fixes and updates to docs.

## 1.0.0

- Initial release.
