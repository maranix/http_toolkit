# Changelog

## 1.0.0

- Initial release of `http_toolkit`.
- Added `Client` with Interceptor and Middleware support.
- Added built-in middlewares:
    - `RetryMiddleware`
    - `LoggerMiddleware`
    - `BearerAuthMiddleware`
    - `BasicAuthMiddleware`
    - `HeadersMiddleware`
- Added `ResponseExtensions` for JSON parsing and status checks.
- Added `ClientExtensions` for easier query parameter handling.
