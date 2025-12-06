# Changelog

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
