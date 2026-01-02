import 'package:collection/collection.dart';
import 'package:dogceo/repositories/models/models.dart';
import 'package:dogceo/repositories/repositories.dart';
import 'package:dogceo/utilities/utilities.dart';

final class BreedListViewModel extends ViewModel {
  BreedListViewModel({required DogRepository dogRepository})
    : _dogRepository = dogRepository;

  final DogRepository _dogRepository;

  late final Task<Result<Map<Breed, List<SubBreed>>>> _allBreedsMap;
  late final Task<Result<List<Breed>>> breedList;

  @override
  void init() {
    breedList = Task();

    _allBreedsMap = Task()
      ..addDependency(breedList, (task) {
        final isRunning = _allBreedsMap.running;
        final doesNotHaveBreeds = !_allBreedsMap.hasData;

        if (isRunning || doesNotHaveBreeds) return;

        task.run(
          () => switch (_allBreedsMap.data) {
            Ok(:final data) => Ok(data.keys.toList()),
            Error(:final error, :final stackTrace) => Error(
              error,
              stackTrace: stackTrace,
            ),
          },
        );
      });

    breedList.hookRunningStateTo(_allBreedsMap);

    super.init();
  }

  void getAllBreeds() => _allBreedsMap.runAsync(_dogRepository.getAllBreeds);

  List<SubBreed> getSubBreedList(Breed breed) =>
      UnmodifiableListView(switch (_allBreedsMap.data) {
        Ok(:final data) => data[breed] ?? [],
        _ => [],
      });

  @override
  void dispose() {
    breedList.dispose();
    _allBreedsMap.dispose();

    super.dispose();
  }
}
