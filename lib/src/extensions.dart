import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_toolkit/src/types.dart';

/// Extensions for parsing HTTP response bodies as JSON.
///
/// These extensions provide convenient methods for decoding JSON response
/// bodies into typed Dart objects.
///
/// ## When to Use
///
/// Use these extensions when you have an [http.Response] and need to
/// parse its body as JSON. For type-safe request+response handling,
/// prefer the `*Decoded` methods on [RequestExtension].
///
/// ## Example
///
/// ```dart
/// final response = await client.get(uri);
/// final user = response.mapJson<User, Map<String, dynamic>>(User.fromJson);
/// ```
extension ResponseBodyExtension on http.Response {
  /// Parses the response body as a JSON object.
  ///
  /// Returns the decoded JSON as a `Map<String, dynamic>`.
  ///
  /// ## Failure Cases
  ///
  /// Throws [FormatException] when:
  /// - Response body is not valid JSON
  /// - Decoded JSON is not a Map (e.g., it's an array or primitive)
  ///
  /// ## Example
  ///
  /// ```dart
  /// final response = await client.get(Uri.parse('/user/1'));
  /// final data = response.jsonMap(); // {'id': 1, 'name': 'John'}
  /// ```
  ///
  /// ## Better Alternative
  ///
  /// For type-safe parsing, use [mapJson] with a typed mapper function.
  Map<String, dynamic> jsonMap() =>
      mapJson<Map<String, dynamic>, Map<String, dynamic>>((json) => json);

  /// Parses the response body as a JSON array.
  ///
  /// Returns the decoded JSON as a `List<dynamic>`.
  ///
  /// ## Failure Cases
  ///
  /// Throws [FormatException] when:
  /// - Response body is not valid JSON
  /// - Decoded JSON is not a List (e.g., it's an object or primitive)
  /// - [T] does not conform to children inside the List
  ///
  /// ## Example
  ///
  /// ```dart
  /// final response = await client.get(Uri.parse('/users'));
  /// final items = response.jsonList(); // [{...}, {...}, ...]
  /// ```
  ///
  /// ## Better Alternative
  ///
  /// For type-safe parsing, use [mapJson] with a typed mapper function.
  List<T> jsonList<T extends dynamic>() =>
      mapJson<List<T>, List<dynamic>>((json) => json.cast<T>());

  /// Parses the response body as JSON and applies a mapper function.
  ///
  /// This is the most flexible JSON parsing method, allowing you to
  /// decode the response and transform it into any type.
  ///
  /// ## Type Parameters
  ///
  /// - [R]: The return type after mapping
  /// - [T]: The expected JSON type (usually `Map<String, dynamic>` or `List<dynamic>`)
  ///
  /// ## Failure Cases
  ///
  /// Throws [FormatException] when:
  /// - Response body is not valid JSON
  /// - Decoded JSON type does not match [T]
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Parse as a typed object
  /// final user = response.mapJson<User, Map<String, dynamic>>(User.fromJson);
  ///
  /// // Parse a list of objects
  /// final users = response.mapJson<List<User>, List<dynamic>>(
  ///   (list) => list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList(),
  /// );
  ///
  /// // Extract a nested field
  /// final items = response.mapJson<List<dynamic>, Map<String, dynamic>>(
  ///   (json) => json['data'] as List<dynamic>,
  /// );
  /// ```
  R mapJson<R, T extends Object>([ResponseBodyMapper<R, T>? mapper]) {
    final decoded = jsonDecode(body);
    if (decoded is! T) {
      throw FormatException(
        'Expected JSON of type $T, '
        'got ${decoded.runtimeType}',
      );
    }

    if (mapper == null) {
      return decoded as R;
    }

    return mapper(decoded);
  }
}

/// Extensions for checking HTTP response status codes.
///
/// These extensions provide convenient boolean getters for common
/// HTTP status code categories.
///
/// ## Example
///
/// ```dart
/// if (response.isSuccess) {
///   // Handle 2xx response
/// } else if (response.isClientError) {
///   // Handle 4xx response
/// } else if (response.isServerError) {
///   // Handle 5xx response
/// }
/// ```
extension ResponseStatusExtension on http.Response {
  /// Returns `true` if the status code is in the 2xx range (200–299).
  ///
  /// Indicates a successful response.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Returns `true` if the status code is in the 3xx range (300–399).
  ///
  /// Indicates a redirect response.
  bool get isRedirectCode => statusCode >= 300 && statusCode < 400;

  /// Returns `true` if the status code is in the 4xx range (400–499).
  ///
  /// Indicates a client error (bad request, unauthorized, not found, etc.).
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Returns `true` if the status code is in the 5xx range (500–599).
  ///
  /// Indicates a server error.
  bool get isServerError => statusCode >= 500 && statusCode < 600;
}

/// Extensions for making type-safe HTTP requests with JSON decoding.
///
/// These extensions combine HTTP requests with JSON parsing and optional
/// response validation in a single method call.
///
/// ## When to Use
///
/// Use `*Decoded` methods when you need to:
/// - Make an HTTP request and parse the JSON response in one step
/// - Apply response validation before parsing
/// - Get type-safe domain objects directly from API calls
///
/// ## Example
///
/// ```dart
/// final user = await client.getDecoded<User, Map<String, dynamic>>(
///   Uri.parse('https://api.example.com/user/1'),
///   mapper: User.fromJson,
///   responseValidator: ResponseValidator.success,
/// );
/// ```
extension RequestExtension on http.Client {
  /// Performs a GET request and decodes the JSON response.
  ///
  /// ## Parameters
  ///
  /// - [url]: The URL to request
  /// - [mapper]: Optional function to transform JSON type [T] into the result type [R]
  /// - [responseValidator]: Optional validator to check response before parsing
  /// - [headers]: Optional HTTP headers to include
  ///
  /// ## When to Use
  ///
  /// - Fetching a single resource by ID
  /// - Loading configuration or metadata
  /// - Any GET request that returns JSON
  ///
  /// ## Failure Cases
  ///
  /// Throws:
  /// - Network errors from the underlying HTTP client
  /// - Exceptions from [responseValidator] if validation fails
  /// - [FormatException] if JSON parsing fails
  ///
  /// ## Example
  ///
  /// ```dart
  /// final user = await client.getDecoded<User, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/users/123'),
  ///   mapper: User.fromJson,
  ///   responseValidator: ResponseValidator.success,
  /// );
  /// ```
  Future<R> getDecoded<R extends dynamic, T extends Object>(
    Uri url, {
    ResponseBodyMapper<R, T>? mapper,
    ResponseValidator? responseValidator,
    Map<String, String>? headers,
  }) async {
    final response = await get(url, headers: headers);

    responseValidator?.call(response);

    return response.mapJson(mapper);
  }

  /// Performs a POST request and decodes the JSON response.
  ///
  /// ## Parameters
  ///
  /// - [url]: The URL to request
  /// - [mapper]: Optional function to transform JSON type [T] into the result type [R]
  /// - [responseValidator]: Optional validator to check response before parsing
  /// - [headers]: Optional HTTP headers to include
  /// - [body]: The request body (String, List&lt;int&gt;, or Map&lt;String, String&gt;)
  ///
  /// ## When to Use
  ///
  /// - Creating new resources
  /// - Submitting forms or data
  /// - Any POST request that returns JSON
  ///
  /// ## Failure Cases
  ///
  /// Throws:
  /// - Network errors from the underlying HTTP client
  /// - Exceptions from [responseValidator] if validation fails
  /// - [FormatException] if JSON parsing fails
  ///
  /// ## Example
  ///
  /// ```dart
  /// final newUser = await client.postDecoded<User, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/users'),
  ///   body: jsonEncode({'name': 'Alice', 'email': 'alice@example.com'}),
  ///   headers: {'Content-Type': 'application/json'},
  ///   mapper: User.fromJson,
  ///   responseValidator: ResponseValidator.created,
  /// );
  /// ```
  Future<R> postDecoded<R extends dynamic, T extends Object>(
    Uri url, {
    ResponseBodyMapper<R, T>? mapper,
    ResponseValidator? responseValidator,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await post(
      url,
      headers: headers,
      body: body,
    );

    responseValidator?.call(response);

    return response.mapJson(mapper);
  }

  /// Performs a PUT request and decodes the JSON response.
  ///
  /// ## Parameters
  ///
  /// - [url]: The URL to request
  /// - [mapper]: Optional function to transform JSON type [T] into the result type [R]
  /// - [responseValidator]: Optional validator to check response before parsing
  /// - [headers]: Optional HTTP headers to include
  /// - [body]: The request body (String, List&lt;int&gt;, or Map&lt;String, String&gt;)
  ///
  /// ## When to Use
  ///
  /// - Replacing an entire resource
  /// - Full updates where all fields are provided
  ///
  /// ## Failure Cases
  ///
  /// Throws:
  /// - Network errors from the underlying HTTP client
  /// - Exceptions from [responseValidator] if validation fails
  /// - [FormatException] if JSON parsing fails
  ///
  /// ## Example
  ///
  /// ```dart
  /// final updatedUser = await client.putDecoded<User, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/users/123'),
  ///   body: jsonEncode({'name': 'Alice Updated', 'email': 'alice@example.com'}),
  ///   headers: {'Content-Type': 'application/json'},
  ///   mapper: User.fromJson,
  ///   responseValidator: ResponseValidator.success,
  /// );
  /// ```
  Future<R> putDecoded<R extends dynamic, T extends Object>(
    Uri url, {
    required ResponseBodyMapper<R, T> mapper,
    ResponseValidator? responseValidator,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await put(
      url,
      headers: headers,
      body: body,
    );

    responseValidator?.call(response);

    return response.mapJson(mapper);
  }

  /// Performs a PATCH request and decodes the JSON response.
  ///
  /// ## Parameters
  ///
  /// - [url]: The URL to request
  /// - [mapper]: Optional function to transform JSON type [T] into the result type [R]
  /// - [responseValidator]: Optional validator to check response before parsing
  /// - [headers]: Optional HTTP headers to include
  /// - [body]: The request body (String, List&lt;int&gt;, or Map&lt;String, String&gt;)
  ///
  /// ## When to Use
  ///
  /// - Partial resource updates
  /// - When only specific fields need to be modified
  ///
  /// ## Failure Cases
  ///
  /// Throws:
  /// - Network errors from the underlying HTTP client
  /// - Exceptions from [responseValidator] if validation fails
  /// - [FormatException] if JSON parsing fails
  ///
  /// ## Example
  ///
  /// ```dart
  /// final updatedUser = await client.patchDecoded<User, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/users/123'),
  ///   body: jsonEncode({'name': 'New Name'}), // Only updating name
  ///   headers: {'Content-Type': 'application/json'},
  ///   mapper: User.fromJson,
  ///   responseValidator: ResponseValidator.success,
  /// );
  /// ```
  Future<R> patchDecoded<R extends dynamic, T extends Object>(
    Uri url, {
    ResponseBodyMapper<R, T>? mapper,
    ResponseValidator? responseValidator,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await patch(
      url,
      headers: headers,
      body: body,
    );

    responseValidator?.call(response);

    return response.mapJson(mapper);
  }

  /// Performs a DELETE request and decodes the JSON response.
  ///
  /// ## Parameters
  ///
  /// - [url]: The URL to request
  /// - [mapper]: Optional function to transform JSON type [T] into the result type [R]
  /// - [responseValidator]: Optional validator to check response before parsing
  /// - [headers]: Optional HTTP headers to include
  /// - [body]: The request body (String, List&lt;int&gt;, or Map&lt;String, String&gt;)
  ///
  /// ## When to Use
  ///
  /// - Deleting resources
  /// - When the delete returns a confirmation response
  ///
  /// ## Failure Cases
  ///
  /// Throws:
  /// - Network errors from the underlying HTTP client
  /// - Exceptions from [responseValidator] if validation fails
  /// - [FormatException] if JSON parsing fails
  ///
  /// ## Example
  ///
  /// ```dart
  /// // When delete returns the deleted resource
  /// final deleted = await client.deleteDecoded<User, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/users/123'),
  ///   mapper: User.fromJson,
  ///   responseValidator: ResponseValidator.success,
  /// );
  ///
  /// // When delete returns no content
  /// await client.deleteDecoded<void, Map<String, dynamic>>(
  ///   Uri.parse('https://api.example.com/users/123'),
  ///   mapper: (_) {},
  ///   responseValidator: ResponseValidator.successOrNoContent,
  /// );
  /// ```
  ///
  /// ## Notes
  ///
  /// Many APIs return 204 No Content for successful deletes. In that case,
  /// use `ResponseValidator.successOrNoContent` and handle the empty body
  /// appropriately in your mapper.
  Future<R> deleteDecoded<R extends dynamic, T extends Object>(
    Uri url, {
    ResponseBodyMapper<R, T>? mapper,
    ResponseValidator? responseValidator,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await delete(
      url,
      headers: headers,
      body: body,
    );

    responseValidator?.call(response);

    return response.mapJson(mapper);
  }
}
