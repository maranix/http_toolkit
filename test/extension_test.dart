import 'package:http/testing.dart';
import 'package:http_toolkit/http_toolkit.dart';
import 'package:test/test.dart';

void main() {
  group('ResponseExtensions', () {
    test('json returns decoded JSON', () {
      final response = Response('{"key": "value"}', 200);
      expect(response.json, {'key': 'value'});
    });

    test('json throws on invalid JSON', () {
      final response = Response('invalid json', 200);
      expect(() => response.json, throwsFormatException);
    });

    test('jsonMap returns Map when body is object', () {
      final response = Response('{"key": "value"}', 200);
      expect(response.jsonMap, {'key': 'value'});
    });

    test('jsonMap throws FormatException when body is list', () {
      final response = Response('[1, 2]', 200);
      expect(() => response.jsonMap, throwsFormatException);
    });

    test('jsonList returns List when body is array', () {
      final response = Response('[1, 2, 3]', 200);
      expect(response.jsonList, [1, 2, 3]);
    });

    test('jsonList throws FormatException when body is map', () {
      final response = Response('{}', 200);
      expect(() => response.jsonList, throwsFormatException);
    });

    // statusCode checks
    test('isSuccess returns true for 200-299', () {
      expect(Response('', 200).isSuccess, isTrue);
      expect(Response('', 299).isSuccess, isTrue);
      expect(Response('', 199).isSuccess, isFalse);
      expect(Response('', 300).isSuccess, isFalse);
    });

    test('isRedirectCode returns true for 300-399', () {
      expect(Response('', 300).isRedirectCode, isTrue);
      expect(Response('', 399).isRedirectCode, isTrue);
      expect(Response('', 299).isRedirectCode, isFalse);
      expect(Response('', 400).isRedirectCode, isFalse);
    });

    test('isClientError returns true for 400-499', () {
      expect(Response('', 400).isClientError, isTrue);
      expect(Response('', 499).isClientError, isTrue);
      expect(Response('', 399).isClientError, isFalse);
      expect(Response('', 500).isClientError, isFalse);
    });

    test('isServerError returns true for 500-599', () {
      expect(Response('', 500).isServerError, isTrue);
      expect(Response('', 599).isServerError, isTrue);
      expect(Response('', 499).isServerError, isFalse);
      expect(Response('', 600).isServerError, isFalse);
    });
  });

  group('ClientExtensions', () {
    test('get adds queryParameters to URL', () async {
      final mockInner = MockClient((request) async {
        expect(request.url.queryParameters, {'a': '1', 'b': '2'});
        return Response('ok', 200);
      });

      final client = Client(inner: mockInner);
      await client.getWith(
        Uri.parse('https://example.com'),
        queryParameters: {'a': '1', 'b': '2'},
      );
    });

    test('get merges queryParameters with existing ones', () async {
      final mockInner = MockClient((request) async {
        expect(request.url.queryParameters, {'a': '1', 'b': '2'});
        return Response('ok', 200);
      });

      final client = Client(inner: mockInner);
      await client.getWith(
        Uri.parse('https://example.com?a=1'),
        queryParameters: {'b': '2'},
      );
    });
  });
}
