import 'package:async/async.dart';
import 'package:http_toolkit/http_toolkit.dart' as http;
import 'package:jph/user.dart';

final class JSONPlacehoderService {
  JSONPlacehoderService(this._client);

  final http.Client _client;

  Future<Result<List<User>>> getAllUsers() async =>
      _client.getDecoded<Result<List<User>>, List>(
        Uri.parse("/users"),
        mapper: (body) {
          try {
            final json = body.cast<Map<String, dynamic>>();
            return ValueResult(json.map(User.fromJson).toList());
          } on Exception catch (e, st) {
            return ErrorResult(e, st);
          }
        },
        responseValidator: (res) {
          http.ResponseValidator.success(res);
          http.ResponseValidator.jsonContentType(res);
          http.ResponseValidator.notEmpty(res);
        },
      );
}
