// ignore_for_file: constant_identifier_names

abstract final class EnvConst {
  static const DOG_CEO_BASE_URL = String.fromEnvironment("DOG_CEO_BASE_URL");
}

abstract final class DogCeoEndpoint {
  static const listAllBreeds = "/breeds/list/all";

  static const randomImage = "/breeds/image/random";
  static String randomImageList(int count) => "/breeds/image/random/$count";

  static String breedRandomImage(String slug) => "/breed/$slug/images/random";
  static String breedAllImages(String slug) => "/breed/$slug/images";
  static String breedImages({required String slug, required int count}) =>
      "/breed/$slug/images/random/$count";

  static String subBreedRandomImage({
    required String breedSlug,
    required String subBreedSlug,
  }) => "/breed/$breedSlug/$subBreedSlug/images/random";
  static String subBreedAllImages({
    required String breedSlug,
    required String subBreedSlug,
  }) => "/breed/$breedSlug/$subBreedSlug/images";
  static String subBreedImages({
    required String breedSlug,
    required String subBreedSlug,
    required int count,
  }) => "/breed/$breedSlug/$subBreedSlug/images/random/$count";
}
