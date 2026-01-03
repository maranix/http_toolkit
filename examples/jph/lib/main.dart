import 'dart:convert';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:http_toolkit/http_toolkit.dart' as http;
import 'package:jph/jsonplacehoder_service.dart';
import 'package:jph/user.dart';

final class URLResponseCacheMiddleware extends http.AsyncMiddleware {
  final Map<Uri, http.Response> _cache = {};
  Map<Uri, http.Response> get cache => UnmodifiableMapView(_cache);

  int _hits = 0;
  int get hits => _hits;

  int get cachedUrlCount => _cache.keys.length;

  @override
  Future<http.StreamedResponse> handle(
    http.BaseRequest request,
    http.RequestHandler next,
  ) async {
    if (request.method != "GET") {
      return next(request);
    }

    // Return from cache, if exists
    if (_cache.containsKey(request.url)) {
      final cachedResponse = _cache[request.url]!;
      final byteStream = http.ByteStream.fromBytes(
        utf8.encode(cachedResponse.body),
      );

      _hits += 1;

      // When cached response is served 5 times, then clear the entire cache.
      //
      // This is just for testing. Since we are only caching a single URL.

      // if (_hits == 5) {
      //   _hits = 0;
      // }

      return http.StreamedResponse(
        byteStream,
        cachedResponse.statusCode,
        request: cachedResponse.request,
        reasonPhrase: cachedResponse.reasonPhrase,
        headers: cachedResponse.headers,
        isRedirect: cachedResponse.isRedirect,
        persistentConnection: cachedResponse.persistentConnection,
      );
    } else {
      // otherwise cache it
      final streamResponse = await next(request);

      // Cache response
      if (streamResponse.request != null) {
        final bytes = await streamResponse.stream.toBytes();
        final response = http.Response.bytes(
          bytes,
          streamResponse.statusCode,
          request: streamResponse.request,
          reasonPhrase: streamResponse.reasonPhrase,
          headers: streamResponse.headers,
          isRedirect: streamResponse.isRedirect,
          persistentConnection: streamResponse.persistentConnection,
        );

        _cache[streamResponse.request!.url] = response;

        /// Return streamed response
        final byteStream = http.ByteStream.fromBytes(bytes);
        return http.StreamedResponse(
          byteStream,
          streamResponse.statusCode,
          request: streamResponse.request,
          reasonPhrase: streamResponse.reasonPhrase,
          headers: streamResponse.headers,
          isRedirect: streamResponse.isRedirect,
          persistentConnection: streamResponse.persistentConnection,
        );
      }

      return streamResponse;
    }
  }
}

void main() {
  final cacheMiddleware = URLResponseCacheMiddleware();

  final client = http.Client(
    middlewares: [
      cacheMiddleware,
      http.BaseUrlMiddleware(const String.fromEnvironment("BASE_URL")),
      http.LoggerMiddleware(),
    ],
  );
  final service = JSONPlacehoderService(client);

  runApp(MyApp(service: service, cache: cacheMiddleware));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.service, required this.cache});

  final JSONPlacehoderService service;
  final URLResponseCacheMiddleware cache;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSONPlaceholder',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: AllUserPage(service: service, cache: cache),
    );
  }
}

class AllUserPage extends StatefulWidget {
  const AllUserPage({super.key, required this.service, required this.cache});

  final JSONPlacehoderService service;
  final URLResponseCacheMiddleware cache;

  @override
  State<AllUserPage> createState() => _AllUserPageState();
}

class _AllUserPageState extends State<AllUserPage> {
  late final ValueNotifier<bool> _loading;
  late final ValueNotifier<Result<List<User>>> _userListNotifier;

  Future<void> fetchUsers() async {
    _loading.value = true;
    _userListNotifier.value = await widget.service.getAllUsers();
    _loading.value = false;

    print(
      "Cached Urls: ${widget.cache.cachedUrlCount}"
      "\n"
      "Successful Hits: ${widget.cache.hits}",
    );
  }

  @override
  void initState() {
    super.initState();

    _loading = .new(false);
    _userListNotifier = .new(ValueResult(<User>[]));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUsers();
    });
  }

  @override
  void dispose() {
    _userListNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      floatingActionButton: FloatingActionButton.small(
        onPressed: fetchUsers,
        child: Icon(Icons.refresh_rounded),
      ),
      body: ValueListenableBuilder(
        valueListenable: _loading,
        builder: (context, loading, child) {
          if (loading) {
            return Center(child: CircularProgressIndicator.adaptive());
          }

          return child!;
        },
        child: ValueListenableBuilder(
          valueListenable: _userListNotifier,
          builder: (context, data, _) {
            return switch (data) {
              ValueResult(:final value) => ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  final user = value[index];

                  return ListTile(
                    title: Text(user.name),
                    leading: Icon(Icons.person_rounded),
                    titleAlignment: .top,
                    subtitle: Column(
                      crossAxisAlignment: .start,
                      spacing: 4,
                      children: [
                        Text(user.username),
                        Text(user.email),
                        Text(user.phone),

                        // Extra space of 8 pixels
                        const SizedBox.shrink(),
                        Text(user.company.name),
                      ],
                    ),
                  );
                },
              ),
              ErrorResult(:final error) => Center(
                child: Text(error.toString()),
              ),
              _ => Text("Sucka!, it didn't work"),
            };
          },
        ),
      ),
    );
  }
}
