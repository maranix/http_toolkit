import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:dogceo/constants.dart';
import 'package:dogceo/services/service.dart';
import 'package:dogceo/types.dart';
import 'package:http/http.dart' as http;
import 'package:dogceo/services/dog_service/models/response.dart';

abstract interface class DogService extends Service {
  Future<AllBreedsResponse> getAllBreeds();
  Future<ImageResponse> getRandomImage();
  Future<ImageListResponse> getRandomImageList(int count);

  Future<ImageListResponse> getBreedImageList(String slug);
  Future<ImageResponse> getBreedRandomImage(String slug);
  Future<ImageListResponse> getBreedRandomImageList({
    required String slug,
    required int count,
  });

  Future<ImageListResponse> getSubBreedImageList({
    required String breedSlug,
    required String subBreedSlug,
  });
  Future<ImageResponse> getSubBreedRandomImage({
    required String breedSlug,
    required String subBreedSlug,
  });
  Future<ImageListResponse> getSubBreedRandomImageList({
    required String breedSlug,
    required String subBreedSlug,
    required int count,
  });
}

final class DogCeoService implements DogService {
  DogCeoService({required String baseURL, http.Client? client})
    : _baseURL = baseURL,
      _client = client ?? http.Client();

  final String _baseURL;
  final http.Client _client;

  /// [T] represents the type of decoded `JSON`.
  /// [R] represents the type of [mapped] object, must be a child of [DogServiceResponse].
  Future<R> _fetch<R extends DogServiceResponse, T>(
    String endpoint, {
    R Function(T)? mapper,
  }) async {
    final response = await _client.get(_buildUrl(endpoint));

    if (response.statusCode != io.HttpStatus.ok) {
      throw io.HttpException(
        "Request failed with status code: ${response.statusCode}",
        uri: response.request?.url,
      );
    }

    final json = convert.jsonDecode(response.body) as T;

    if (mapper == null) {
      return json as R;
    }

    return mapper(json);
  }

  Uri _buildUrl(String uri) {
    final url = Uri.tryParse("$_baseURL$uri");
    if (url == null) {
      throw FormatException(
        "Invalid url: Unable to parse $uri into an Uri object"
        "Expected an Uri object, got $url",
        url,
      );
    }

    return url;
  }

  @override
  Future<AllBreedsResponse> getAllBreeds() => _fetch<AllBreedsResponse, JSON>(
    DogCeoEndpoint.listAllBreeds,
    mapper: AllBreedsResponse.fromJson,
  );

  @override
  Future<ImageResponse> getRandomImage() => _fetch<ImageResponse, JSON>(
    DogCeoEndpoint.randomImage,
    mapper: ImageResponse.fromJson,
  );

  @override
  Future<ImageListResponse> getRandomImageList(int count) =>
      _fetch<ImageListResponse, JSON>(
        DogCeoEndpoint.randomImageList(count),
        mapper: ImageListResponse.fromJson,
      );

  @override
  void dispose() {
    _client.close();
  }

  @override
  Future<ImageListResponse> getBreedImageList(String slug) =>
      _fetch<ImageListResponse, JSON>(
        DogCeoEndpoint.breedAllImages(slug),
        mapper: ImageListResponse.fromJson,
      );

  @override
  Future<ImageResponse> getBreedRandomImage(String slug) =>
      _fetch<ImageResponse, JSON>(
        DogCeoEndpoint.breedRandomImage(slug),
        mapper: ImageResponse.fromJson,
      );

  @override
  Future<ImageListResponse> getBreedRandomImageList({
    required String slug,
    required int count,
  }) => _fetch<ImageListResponse, JSON>(
    DogCeoEndpoint.breedImages(slug: slug, count: count),
    mapper: ImageListResponse.fromJson,
  );

  @override
  Future<ImageListResponse> getSubBreedImageList({
    required String breedSlug,
    required String subBreedSlug,
  }) => _fetch<ImageListResponse, JSON>(
    DogCeoEndpoint.subBreedAllImages(
      breedSlug: breedSlug,
      subBreedSlug: subBreedSlug,
    ),
    mapper: ImageListResponse.fromJson,
  );

  @override
  Future<ImageResponse> getSubBreedRandomImage({
    required String breedSlug,
    required String subBreedSlug,
  }) => _fetch<ImageResponse, JSON>(
    DogCeoEndpoint.subBreedRandomImage(
      breedSlug: breedSlug,
      subBreedSlug: subBreedSlug,
    ),
    mapper: ImageResponse.fromJson,
  );

  @override
  Future<ImageListResponse> getSubBreedRandomImageList({
    required String breedSlug,
    required String subBreedSlug,
    required int count,
  }) => _fetch<ImageListResponse, JSON>(
    DogCeoEndpoint.subBreedImages(
      breedSlug: breedSlug,
      subBreedSlug: subBreedSlug,
      count: count,
    ),
    mapper: ImageListResponse.fromJson,
  );
}
