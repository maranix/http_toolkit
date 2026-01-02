import 'dart:async';

import 'package:dogceo/repositories/dog_repository.dart';
import 'package:dogceo/repositories/models/models.dart';
import 'package:dogceo/utilities/utilities.dart';

final class RandomImageViewModel extends ViewModel {
  RandomImageViewModel({required DogRepository dogRepository})
    : _dogRepository = dogRepository;

  final DogRepository _dogRepository;

  late final Task<Result<DogImage>> randomImage;
  late final Task<bool> slideshowRunning;

  late final StreamSubscription<void> _slideshowSubscription;

  @override
  void init() {
    randomImage = Task();
    slideshowRunning = Task.init(false);

    _slideshowSubscription = Stream.periodic(
      const Duration(seconds: 5),
    ).listen((_) => getRandomImage())..pause();

    randomImage.runAsync(() async {
      final result = await _dogRepository.getRandomImage();

      toggleSlideshow();
      return result;
    });

    super.init();
  }

  void getRandomImage() => randomImage.runAsync(_dogRepository.getRandomImage);

  void toggleSlideshow() {
    if (_slideshowSubscription.isPaused) {
      _slideshowSubscription.resume();
      slideshowRunning.run(() => true);
      return;
    }

    _slideshowSubscription.pause();
    slideshowRunning.run(() => false);
  }

  @override
  void dispose() async {
    await _slideshowSubscription.cancel();

    randomImage.dispose();
    slideshowRunning.dispose();

    super.dispose();
  }
}
