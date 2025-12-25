import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_toolkit/http_toolkit.dart';
import 'package:test/test.dart';

void main() {
  group('ResponseBodyExtensions', () {
    test('json returns decoded JSON', () {
      final response = Response('{"key": "value"}', 200);
      expect(response.jsonMap(), {'key': 'value'});
    });

    test('json throws on invalid JSON', () {
      final response = Response('invalid json', 200);
      expect(response.jsonMap, throwsFormatException);
    });

    test('jsonMap returns Map when body is object', () {
      final response = Response('{"key": "value"}', 200);
      expect(response.jsonMap(), {'key': 'value'});
    });

    test('jsonMap throws FormatException when body is list', () {
      final response = Response('[1, 2]', 200);
      expect(response.jsonMap, throwsFormatException);
    });

    test('jsonList returns List when body is array', () {
      final response = Response('[1, 2, 3]', 200);
      final expected = [1, 2, 3];

      expect(response.jsonList(), expected);
    });

    test('jsonList enforces types by explicit casting if given T', () {
      const listOfInt = [1, 2, 3];
      const listOfString = ['one', 'two', 'three'];
      const listOfDouble = [1.1, 2.2, 3.3];
      const listOfMap = [
        {'id': 1, 'name': 'user'},
        {'id': 2, 'name': 'user_two'},
        {'id': 3, 'name': 'user_three'},
      ];

      final integerListResponse = Response(jsonEncode(listOfInt), 200);
      final stringListResponse = Response(jsonEncode(listOfString), 200);
      final doubleListResponse = Response(jsonEncode(listOfDouble), 200);
      final mapListResponse = Response(jsonEncode(listOfMap), 200);

      // Match losely dynamic types, all should pass.
      expect(
        integerListResponse.jsonList(),
        unorderedEquals(List.from(listOfInt)),
      );
      expect(
        stringListResponse.jsonList(),
        unorderedEquals(List.from(listOfString)),
      );
      expect(
        doubleListResponse.jsonList(),
        unorderedEquals(List.from(listOfDouble)),
      );
      expect(
        mapListResponse.jsonList(),
        unorderedEquals(List.from(listOfMap)),
      );

      /// Match type of collections
      const listIntMatcher = TypeMatcher<List<int>>();
      const listStringMatcher = TypeMatcher<List<String>>();
      const listDoubleMatcher = TypeMatcher<List<double>>();
      const listJsonMatcher = TypeMatcher<List<Map<String, dynamic>>>();

      expect(integerListResponse.jsonList<int>(), listIntMatcher);
      expect(stringListResponse.jsonList<String>(), listStringMatcher);
      expect(doubleListResponse.jsonList<double>(), listDoubleMatcher);
      expect(mapListResponse.jsonList<Map<String, dynamic>>(), listJsonMatcher);

      // This passes because we are only comparing the type of children inside the List
      // not the `Key` and `Value` inside the Map.
      expect(
        // ignore: strict_raw_type
        mapListResponse.jsonList<Map>(),
        // ignore: strict_raw_type
        isA<List<Map>>(),
      );

      expect(
        // ignore: strict_raw_type
        mapListResponse.jsonList<Map>(),
        isNot(const TypeMatcher<List<Map<int, String>>>()),
      );
    });

    test('jsonList throws FormatException when body is map', () {
      final response = Response('{}', 200);
      expect(response.jsonList, throwsFormatException);
    });
  });

  group('ResponseStatusExtensions', () {
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
    group('getDecoded', () {
      test('returns mapped object on success', () async {
        final mockInner = MockClient((request) async {
          expect(request.method, 'GET');
          return http.Response('{"id": 1}', 200);
        });
        final client = Client(inner: mockInner);

        final result = await client.getDecoded(
          Uri.parse('https://example.com'),
          mapper: (json) => (json! as Map<String, dynamic>)['id'] as int,
        );

        expect(result, 1);
      });

      test('validates response with validator', () {
        final mockInner = MockClient((request) async {
          return http.Response('{"id": 1}', 201);
        });
        final client = Client(inner: mockInner);

        expect(
          () => client.getDecoded(
            Uri.parse('https://example.com'),
            mapper: (json) => json,
            responseValidator: (response) {
              ResponseValidator.statusCode(response, 200);
            },
          ),
          throwsA(isA<HttpException>()),
        );
      });
    });

    group('postDecoded', () {
      test('sends body and returns mapped object', () async {
        final mockInner = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.body, '{"name":"test"}');
          return http.Response('{"id": 1}', 201);
        });
        final client = Client(inner: mockInner);

        final result = await client.postDecoded(
          Uri.parse('https://example.com'),
          body: '{"name":"test"}',
          mapper: (json) => (json! as Map<String, dynamic>)['id'] as int,
        );

        expect(result, 1);
      });
    });

    group('putDecoded', () {
      test('sends body and returns mapped object', () async {
        final mockInner = MockClient((request) async {
          expect(request.method, 'PUT');
          return http.Response('{"id": 1}', 200);
        });
        final client = Client(inner: mockInner);

        final result = await client.putDecoded(
          Uri.parse('https://example.com'),
          mapper: (json) => (json! as Map<String, dynamic>)['id'] as int,
        );

        expect(result, 1);
      });
    });

    group('patchDecoded', () {
      test('sends body and returns mapped object', () async {
        final mockInner = MockClient((request) async {
          expect(request.method, 'PATCH');
          return http.Response('{"id": 1}', 200);
        });
        final client = Client(inner: mockInner);

        final result = await client.patchDecoded(
          Uri.parse('https://example.com'),
          mapper: (json) => (json! as Map<String, dynamic>)['id'] as int,
        );

        expect(result, 1);
      });
    });

    group('deleteDecoded', () {
      test('returns mapped object', () async {
        final mockInner = MockClient((request) async {
          expect(request.method, 'DELETE');
          return http.Response('{"id": 1}', 200);
        });
        final client = Client(inner: mockInner);

        final result = await client.deleteDecoded(
          Uri.parse('https://example.com'),
          mapper: (json) => (json! as Map<String, dynamic>)['id'] as int,
        );

        expect(result, 1);
      });
    });

    group('ResponseValidator integration', () {
      test('success validator passes for 200', () async {
        final mockInner = MockClient((_) async => http.Response('{}', 200));
        final client = Client(inner: mockInner);

        await client.getDecoded(
          Uri.parse('https://example.com'),
          mapper: (_) {},
          responseValidator: ResponseValidator.success,
        );
      });

      test('success validator throws for 404', () {
        final mockInner = MockClient((_) async => http.Response('{}', 404));
        final client = Client(inner: mockInner);

        expect(
          () => client.getDecoded(
            Uri.parse('https://example.com'),
            mapper: (_) {},
            responseValidator: ResponseValidator.success,
          ),
          throwsA(isA<HttpException>()),
        );
      });

      test('created validator passes for 201', () async {
        final mockInner = MockClient((_) async => http.Response('{}', 201));
        final client = Client(inner: mockInner);

        await client.postDecoded(
          Uri.parse('https://example.com'),
          mapper: (_) {},
          responseValidator: ResponseValidator.created,
        );
      });

      test('created validator throws for 200', () {
        final mockInner = MockClient((_) async => http.Response('{}', 200));
        final client = Client(inner: mockInner);

        expect(
          () => client.postDecoded(
            Uri.parse('https://example.com'),
            mapper: (_) {},
            responseValidator: ResponseValidator.created,
          ),
          throwsA(isA<HttpException>()),
        );
      });

      test('successOrNoContent validator passes for 204', () async {
        final mockInner = MockClient((_) async => http.Response('{}', 204));
        final client = Client(inner: mockInner);

        await client.deleteDecoded(
          Uri.parse('https://example.com'),
          mapper: (_) {},
          responseValidator: ResponseValidator.successOrNoContent,
        );
      });

      test('jsonContentType validator passes for application/json', () async {
        final mockInner = MockClient(
          (_) async => http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );
        final client = Client(inner: mockInner);

        await client.getDecoded(
          Uri.parse('https://example.com'),
          mapper: (_) {},
          responseValidator: ResponseValidator.jsonContentType,
        );
      });

      test('jsonContentType validator throws for text/html', () {
        final mockInner = MockClient(
          (_) async =>
              http.Response('{}', 200, headers: {'content-type': 'text/html'}),
        );
        final client = Client(inner: mockInner);

        expect(
          () => client.getDecoded(
            Uri.parse('https://example.com'),
            mapper: (_) {},
            responseValidator: ResponseValidator.jsonContentType,
          ),
          throwsA(isA<HttpException>()),
        );
      });

      test('notEmpty validator throws for empty body', () {
        final mockInner = MockClient((_) async => http.Response('', 200));
        final client = Client(inner: mockInner);

        expect(
          () => client.getDecoded(
            Uri.parse('https://example.com'),
            mapper: (_) {},
            responseValidator: ResponseValidator.notEmpty,
          ),
          throwsA(isA<HttpException>()),
        );
      });
    });

    group('JSON Parsing Edge Cases', () {
      test('throws FormatException on malformed JSON', () {
        final mockInner = MockClient(
          (_) async => http.Response('{invalid}', 200),
        );
        final client = Client(inner: mockInner);

        expect(
          () => client.getDecoded(
            Uri.parse('https://example.com'),
            mapper: (_) {},
          ),
          throwsFormatException,
        );
      });

      test('throws FormatException when mapper sees unexpected type', () {
        final mockInner = MockClient((_) async => http.Response('[1, 2]', 200));
        final client = Client(inner: mockInner);

        expect(
          client.getDecoded<void, Map<String, dynamic>>(
            Uri.parse('https://example.com'),
            mapper: (_) {},
          ),
          throwsFormatException,
        );
      });
    });
  });
}
