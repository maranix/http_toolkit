import 'package:dogceo/repositories/models/models.dart';
import 'package:dogceo/repositories/repository.dart';
import 'package:dogceo/services/services.dart';
import 'package:dogceo/constants.dart';
import 'package:dogceo/utilities/result.dart';

final class DogRepository extends Repository {
  DogRepository({DogService? service})
    : _service = service ?? DogCeoService(baseURL: EnvConst.DOG_CEO_BASE_URL);

  final DogService _service;

  Future<Result<T>> _compute<T>(Future<T> Function() computation) async {
    try {
      final data = await computation();
      return Ok(data);
    } on Exception catch (e, st) {
      return Error(e, stackTrace: st);
    }
  }

  Future<Result<Map<Breed, List<SubBreed>>>> getAllBreeds() async =>
      _compute(() async {
        final data = await _service.getAllBreeds();

        if (data.isSuccess) {
          Map<Breed, List<SubBreed>> map = .new();

          for (final entry in data.message.entries) {
            final breed = Breed(entry.key);
            final subBreeds = entry.value.map(
              (s) => SubBreed(breed: breed, slug: s),
            );

            map.putIfAbsent(breed, () => []).addAll(subBreeds);
          }

          return map;
        }

        throw Exception("GetAllBreeds: Something went wrong");
      });

  Future<Result<DogImage>> getRandomImage() async => _compute(() async {
    final data = await _service.getRandomImage();

    if (data.isSuccess) {
      return DogImage.fromString(data.message);
    }

    throw Exception("GetRandomImage: Something went wrong");
  });

  Future<Result<List<DogImage>>> getRandomImageList(int count) async =>
      _compute(() async {
        final data = await _service.getRandomImageList(count);

        if (data.isSuccess) {
          return data.message.map(DogImage.fromString).toList();
        }

        throw Exception("GetRandomImageList: Something went wrong");
      });

  Future<Result<List<DogImage>>> getBreedImageList(String slug) =>
      _compute(() async {
        final data = await _service.getBreedImageList(slug);

        if (data.isSuccess) {
          return data.message.map(DogImage.fromString).toList();
        }

        throw Exception("GetBreedImageList: Something went wrong");
      });

  Future<Result<DogImage>> getBreedRandomImage(String slug) =>
      _compute(() async {
        final data = await _service.getBreedRandomImage(slug);

        if (data.isSuccess) {
          return DogImage.fromString(data.message);
        }

        throw Exception("GetBreedRandomImage: Something went wrong");
      });

  Future<Result<List<DogImage>>> getBreedRandomImageList({
    required String slug,
    required int count,
  }) => _compute(() async {
    final data = await _service.getBreedRandomImageList(
      slug: slug,
      count: count,
    );

    if (data.isSuccess) {
      return data.message.map(DogImage.fromString).toList();
    }

    throw Exception("GetBreedRandomImageList: Something went wrong");
  });

  Future<Result<List<DogImage>>> getSubBreedImageList({
    required String breedSlug,
    required String subBreedSlug,
  }) => _compute(() async {
    final data = await _service.getSubBreedImageList(
      breedSlug: breedSlug,
      subBreedSlug: subBreedSlug,
    );

    if (data.isSuccess) {
      return data.message.map(DogImage.fromString).toList();
    }

    throw Exception("GetSubBreedImageList: Something went wrong");
  });

  Future<Result<DogImage>> getSubBreedRandomImage({
    required String breedSlug,
    required String subBreedSlug,
  }) => _compute(() async {
    final data = await _service.getSubBreedRandomImage(
      breedSlug: breedSlug,
      subBreedSlug: subBreedSlug,
    );

    if (data.isSuccess) {
      return DogImage.fromString(data.message);
    }

    throw Exception("GetSubBreedRandomImage: Something went wrong");
  });

  Future<Result<List<DogImage>>> getSubBreedRandomImageList({
    required String breedSlug,
    required String subBreedSlug,
    required int count,
  }) => _compute(() async {
    final data = await _service.getSubBreedRandomImageList(
      breedSlug: breedSlug,
      subBreedSlug: subBreedSlug,
      count: count,
    );

    if (data.isSuccess) {
      return data.message.map(DogImage.fromString).toList();
    }

    throw Exception("GetSubBreedRandomImageList: Something went wrong");
  });

  @override
  void dispose() {
    _service.dispose();
  }
}
