import 'dart:io' as io;

import 'package:http/http.dart' as http;

/// A function that maps a response body of type [T] to a result of type [R].
///
/// This typedef is used by `*Decoded` methods in `RequestExtension` to
/// transform raw JSON data into typed domain objects.
///
/// ## Type Parameters
///
/// - [R]: The type of the mapped result (your domain object)
/// - [T]: The type of the source JSON (typically `Map<String, dynamic>` or `List<dynamic>`)
///
/// ## Example
///
/// ```dart
/// // Define a mapper for your User model
/// final ResponseBodyMapper<User, Map<String, dynamic>> userMapper = User.fromJson;
///
/// // Or use an inline lambda
/// final user = await client.getDecoded<User, Map<String, dynamic>>(
///   uri,
///   mapper: (json) => User.fromJson(json),
/// );
/// ```
///
/// ## Common Patterns
///
/// ### Factory Constructors
/// Most commonly, you'll pass a factory constructor:
/// ```dart
/// mapper: User.fromJson
/// ```
///
/// ### Extracting Nested Data
/// Extract data from a wrapper object:
/// ```dart
/// mapper: (json) => User.fromJson(json['data']),
/// ```
///
/// ### Parsing Lists
/// When the response is a list:
/// ```dart
/// mapper: (list) => list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList(),
/// ```
typedef ResponseBodyMapper<R, T extends Object> = R Function(T);

/// A function that validates an [http.Response] before JSON parsing.
///
/// Validators inspect the response and throw an exception if validation
/// fails, preventing JSON parsing from proceeding.
///
/// ## When to Use
///
/// - Validate status codes before parsing
/// - Check content-type headers
/// - Ensure response body is not empty
/// - Implement custom business validation rules
///
/// ## Example
///
/// ```dart
/// // Using built-in validators
/// responseValidator: ResponseValidator.success,
///
/// // Combining multiple validators
/// responseValidator: (response) {
///   ResponseValidator.success(response);
///   ResponseValidator.jsonContentType(response);
/// },
///
/// // Custom validator
/// responseValidator: (response) {
///   if (response.headers['x-rate-limit-remaining'] == '0') {
///     throw Exception('Rate limit exceeded');
///   }
/// },
/// ```
///
/// ## Error Handling
///
/// When a validator throws, the exception propagates to the caller
/// and JSON parsing is skipped entirely.
///
/// See also:
/// - [ResponseValidator] for built-in validation functions
typedef ResponseValidatorCallback = void Function(http.Response);

/// Reusable HTTP response validators for common validation patterns.
///
/// A response validator is a function that inspects an [http.Response] and
/// throws an exception if the response does not meet the expected criteria.
/// Validators are typically executed before JSON parsing in `getDecoded`,
/// `postDecoded`, and related methods.
///
/// ## When to Use
///
/// Use validators when you need to:
/// - Ensure API responses have expected status codes before parsing
/// - Validate content-type headers to catch HTML error pages early
/// - Verify response bodies are not empty before attempting to decode
///
/// ## Combining Validators
///
/// You can combine multiple validators in a custom function:
///
/// ```dart
/// await client.getDecoded<User, Map<String, dynamic>>(
///   Uri.parse('https://api.example.com/user'),
///   mapper: User.fromJson,
///   responseValidator: (response) {
///     ResponseValidator.success(response);
///     ResponseValidator.jsonContentType(response);
///     ResponseValidator.notEmpty(response);
///   },
/// );
/// ```
///
/// ## Error Handling
///
/// All validators throw [io.HttpException] on failure, which includes:
/// - A descriptive error message
/// - The request URI for debugging
///
/// ## Alternatives
///
/// For more complex validation logic (e.g., custom business rules, field
/// validation), consider implementing a custom `ResponseValidator` function
/// or using a validation library after JSON parsing.
///
/// See also:
/// - `RequestExtension.getDecoded` for typed JSON requests with validation
abstract final class ResponseValidator {
  /// Ensures the response has the expected HTTP status code.
  ///
  /// Use this validator when an API endpoint must return a specific status
  /// code, such as 201 for resource creation or 204 for successful deletion.
  ///
  /// ## When to Use
  ///
  /// - When your API follows strict status code conventions
  /// - When you need to differentiate between 200 and 201 responses
  /// - For endpoints with well-defined status code semantics
  ///
  /// ## Failure Cases
  ///
  /// Throws [io.HttpException] when:
  /// - Response status code does not match the expected `statusCode`
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Validate creation endpoint returns 201
  /// await client.postDecoded<void, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/users'),
  ///   body: jsonEncode({'name': 'John'}),
  ///   mapper: (_) {},
  ///   responseValidator: (response) {
  ///     ResponseValidator.statusCode(response, 201);
  ///   },
  /// );
  /// ```
  ///
  /// ## Better Alternative
  ///
  /// For common status codes, prefer the dedicated validators:
  /// - [success] for 200-299 range
  /// - [created] for 201
  /// - [successOrNoContent] for 200 or 204
  static void statusCode(http.Response response, int statusCode) {
    final rCode = response.statusCode;
    if (rCode != statusCode) {
      throw io.HttpException(
        'Expected status $statusCode, got $rCode',
        uri: response.request?.url,
      );
    }
  }

  /// Ensures the response status code is in the 2xx range (200–299).
  ///
  /// This is the most common validator for successful API responses.
  /// It accepts any success status code, making it suitable for APIs that
  /// may return 200, 201, or 204 depending on the operation.
  ///
  /// ## When to Use
  ///
  /// - For general-purpose API calls where any success status is acceptable
  /// - When you don't need to distinguish between different success codes
  /// - As a baseline validator combined with other checks
  ///
  /// ## Failure Cases
  ///
  /// Throws [io.HttpException] when:
  /// - Status code is less than 200 (informational)
  /// - Status code is 300 or greater (redirects, client/server errors)
  ///
  /// ## Example
  ///
  /// ```dart
  /// final user = await client.getDecoded<User, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/user/123'),
  ///   mapper: User.fromJson,
  ///   responseValidator: ResponseValidator.success,
  /// );
  /// ```
  ///
  /// ## Better Alternative
  ///
  /// If your API strictly returns 200 for GET requests and 201 for POST,
  /// consider using [statusCode] for more precise validation.
  static void success(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw io.HttpException(
        'Request failed with status: ${response.statusCode}',
        uri: response.request?.url,
      );
    }
  }

  /// Ensures the response status code is 201 (Created).
  ///
  /// Use this validator for POST requests that create new resources.
  /// REST APIs typically return 201 to indicate successful resource creation.
  ///
  /// ## When to Use
  ///
  /// - For POST endpoints that create new resources
  /// - When the API follows REST conventions for resource creation
  /// - To ensure accidental 200 responses are caught as errors
  ///
  /// ## Failure Cases
  ///
  /// Throws [io.HttpException] when:
  /// - Status code is not 201 (e.g., 200, 204, 400, 500)
  ///
  /// ## Example
  ///
  /// ```dart
  /// final newUser = await client.postDecoded<User, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/users'),
  ///   body: jsonEncode({'name': 'Alice', 'email': 'alice@example.com'}),
  ///   mapper: User.fromJson,
  ///   responseValidator: ResponseValidator.created,
  /// );
  /// ```
  ///
  /// ## Notes
  ///
  /// Some APIs return 200 instead of 201 for creation. In such cases,
  /// use [success] or [statusCode] with the appropriate code.
  static void created(http.Response response) => statusCode(response, 201);

  /// Ensures the response status code is 200 (OK) or 204 (No Content).
  ///
  /// Use this validator for PUT, PATCH, or DELETE endpoints that may
  /// return either a response body (200) or no content (204).
  ///
  /// ## When to Use
  ///
  /// - For update or delete operations where the body may be optional
  /// - When the API returns 204 for successful deletions
  /// - For PUT/PATCH that may or may not return the updated resource
  ///
  /// ## Failure Cases
  ///
  /// Throws [io.HttpException] when:
  /// - Status code is not 200 or 204 (e.g., 201, 400, 404, 500)
  ///
  /// ## Example
  ///
  /// ```dart
  /// await client.deleteDecoded<void, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/users/123'),
  ///   mapper: (_) {},
  ///   responseValidator: ResponseValidator.successOrNoContent,
  /// );
  /// ```
  ///
  /// ## Notes
  ///
  /// When status is 204, the response body will be empty. Ensure your
  /// mapper handles null/empty JSON gracefully if using this validator.
  static void successOrNoContent(http.Response response) {
    final code = response.statusCode;
    if (code != 200 && code != 204) {
      throw io.HttpException(
        'Expected 200 or 204, got $code',
        uri: response.request?.url,
      );
    }
  }

  /// Ensures the response content type indicates JSON.
  ///
  /// This validator prevents attempting to parse HTML error pages,
  /// plain text, or other non-JSON responses as JSON, which would
  /// result in confusing `FormatException` errors.
  ///
  /// ## When to Use
  ///
  /// - When calling third-party APIs that may return HTML on errors
  /// - To catch cases where a web server serves an error page instead of JSON
  /// - As an early-fail validator before JSON parsing
  ///
  /// ## Failure Cases
  ///
  /// Throws [io.HttpException] when:
  /// - Response is missing the `content-type` header
  /// - Content type does not contain `application/json`
  ///
  /// ## Example
  ///
  /// ```dart
  /// final data = await client.getDecoded<Data, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/data'),
  ///   mapper: Data.fromJson,
  ///   responseValidator: (response) {
  ///     ResponseValidator.success(response);
  ///     ResponseValidator.jsonContentType(response);
  ///   },
  /// );
  /// ```
  ///
  /// ## Notes
  ///
  /// This accepts any content type containing `application/json`,
  /// including `application/json; charset=utf-8`.
  static void jsonContentType(http.Response response) {
    if (!response.headers.containsKey(io.HttpHeaders.contentTypeHeader)) {
      throw io.HttpException(
        'Missing `content-type` header from response',
        uri: response.request?.url,
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw io.HttpException(
        'Expected JSON response, but received: $contentType',
        uri: response.request?.url,
      );
    }
  }

  /// Ensures the response body is not empty.
  ///
  /// Use this validator when a JSON payload is required and an empty
  /// body would indicate an error condition.
  ///
  /// ## When to Use
  ///
  /// - For endpoints that must always return a response body
  /// - To catch unexpected 204 responses when a body is expected
  /// - Before parsing when null/empty JSON would cause issues
  ///
  /// ## Failure Cases
  ///
  /// Throws [io.HttpException] when:
  /// - Response body is empty or contains only whitespace
  ///
  /// ## Example
  ///
  /// ```dart
  /// final config = await client.getDecoded<Config, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/config'),
  ///   mapper: Config.fromJson,
  ///   responseValidator: (response) {
  ///     ResponseValidator.success(response);
  ///     ResponseValidator.notEmpty(response);
  ///   },
  /// );
  /// ```
  ///
  /// ## Notes
  ///
  /// This validator trims whitespace before checking, so a body with
  /// only spaces or newlines is considered empty.
  static void notEmpty(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw io.HttpException(
        'Response body is empty',
        uri: response.request?.url,
      );
    }
  }
}
