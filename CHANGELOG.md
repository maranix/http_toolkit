# Changelog

## 2.0.0

### Breaking Changes

- **`BackoffStrategy`**: Renamed `getDelay` to `getDelayDuration` for clarity.
- **`RetryMiddleware.whenError`**: Signature changed from `bool Function(Object error)` to `bool Function(Object error, int attempt, Duration nextAttempt)`.
- **`RetryMiddleware.whenResponse`**: Signature changed from `bool Function(BaseResponse response)` to `bool Function(BaseResponse response, int attempt, Duration totalDuration)`.
- **Removed `ClientExtensions.getWith`**: Use `getDecoded` with appropriate parameters instead.

### New Features

- **`ResponseValidator`**: A new utility class providing reusable HTTP response validation functions:
  - `statusCode(response, code)` - Validates specific status code
  - `success(response)` - Validates 2xx range (200-299)
  - `created(response)` - Validates 201 status
  - `successOrNoContent(response)` - Validates 200 or 204
  - `jsonContentType(response)` - Validates `application/json` content-type
  - `notEmpty(response)` - Validates non-empty response body

- **`*Decoded` Client Extensions**: New type-safe JSON decoding methods on `http.Client`:
  - `getDecoded<R, T>` - GET with JSON mapping and optional validation
  - `postDecoded<R, T>` - POST with JSON mapping and optional validation
  - `putDecoded<R, T>` - PUT with JSON mapping and optional validation
  - `patchDecoded<R, T>` - PATCH with JSON mapping and optional validation
  - `deleteDecoded<R, T>` - DELETE with JSON mapping and optional validation

- **Type Aliases**: New `types.dart` exports:
  - `ResponseBodyMapper<R, T>` - Function type for mapping response bodies
  - `ResponseValidator` - Function type for validating responses

### Improvements

- **`RetryMiddleware`**: Enhanced callback signatures provide access to attempt count and delay duration for better observability and control over retry logic.
- **Example**: Updated with `RetryMiddleware` demo showcasing new callback parameters.

## 1.0.0+1

- Minor fixes and updates to docs.

## 1.0.0

- Initial release.
- **Client**: A robust HTTP client wrapper compatible with key `http` package logic.
- **Middleware**: New `Middleware` interface for structured request/response processing.
- **Retry**: `RetryMiddleware` with configurable `BackoffStrategy` (Exponential, Linear, Fixed).
- **Logger**: `LoggerMiddleware` with support for logging headers and bodies, using `print` by default.
- **Auth**: `BearerAuthMiddleware` and `BasicAuthMiddleware`.
- **BaseUrl**: `BaseUrlMiddleware` for convenient URL handling.
- **Interceptors**: Lightweight hooks for `onRequest`, `onResponse`, and `onError`.
- **Extensions**: Useful extensions for `http.Response` (JSON parsing) and `http.Client`.
- Added `ClientExtensions` for easier query parameter handling.
