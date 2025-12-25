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
typedef ResponseValidator = void Function(http.Response);
