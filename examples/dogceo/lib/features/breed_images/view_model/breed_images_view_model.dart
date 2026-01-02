import 'dart:async';

import 'package:dogceo/repositories/models/models.dart';
import 'package:dogceo/repositories/repositories.dart';
import 'package:dogceo/utilities/utilities.dart';

final class BreedImagesViewModel extends ViewModel {
  BreedImagesViewModel({
    required Breed breed,
    required DogRepository repository,
  }) : _breed = breed,
       _dogRepository = repository;

  final Breed _breed;
  final DogRepository _dogRepository;

  late final Task<Result<DogImage>> image;
  late final Task<SubBreed?> selectedSubBreed;
  StreamSubscription<void>? _slideshow;

  void selectSubBreed(SubBreed? breed) => selectedSubBreed.run(() => breed);

  @override
  FutureOr<void> init() {
    image = Task();
    selectedSubBreed = Task.init(null);

    /// Whenever image is updated, make sure to cancel and re-initalize the slideshow
    image.addDependency(image, (_) {
      _slideshow?.cancel();

      _slideshow = Stream<void>.periodic(
        const Duration(seconds: 5),
      ).listen((_) => _fetchImage());
    });

    /// Whenever sub-breed is updated, it'll update `image` and as an effect, slideshow will be recreate,
    ///
    /// See above dependency for better understanding.
    ///
    /// x. Image (fetch) -> Slideshow is created (side effect)
    /// y. SubBreed (Update) -> Image (fetch side effect)
    ///
    /// consider the above `x` and `y` process and side-effect
    ///
    /// since `y` basically triggers the `x` process as a (side-effect) and `x`s side-effect re-initalize the slideshow.
    ///
    /// It's a one way dependency relationship and not a circular one.
    selectedSubBreed.addDependency(image, (_) {
      _fetchImage();
    });

    super.init();
  }

  void _fetchImage() {
    if (selectedSubBreed.data == null) {
      getBreedImage();
    } else {
      getSubBreedImage();
    }
  }

  void getBreedImage() =>
      image.runAsync(() => _dogRepository.getBreedRandomImage(_breed.slug));

  void getSubBreedImage() => image.runAsync(
    () => _dogRepository.getSubBreedRandomImage(
      breedSlug: _breed.slug,
      subBreedSlug: selectedSubBreed.data!.slug,
    ),
  );

  @override
  FutureOr<void> dispose() {
    _slideshow?.cancel();

    image.dispose();
    selectedSubBreed.dispose();

    return super.dispose();
  }
}
