import 'package:dogceo/features/breed_images/breed_images.dart';
import 'package:dogceo/features/breed_list/view_model/breed_list_view_model.dart';
import 'package:dogceo/repositories/repositories.dart';
import 'package:dogceo/utilities/utilities.dart';
import 'package:dogceo/widgets/widgets.dart';
import 'package:flutter/material.dart';

class BreedListScreen extends StatefulWidget {
  const BreedListScreen({super.key});

  @override
  State<BreedListScreen> createState() => _BreedListScreenState();
}

class _BreedListScreenState extends State<BreedListScreen> {
  late final BreedListViewModel _viewModel;

  void _onViewModelInitialized() {
    if (_viewModel.initialized) {
      _viewModel.getAllBreeds();
    }
  }

  @override
  void initState() {
    super.initState();

    _viewModel = BreedListViewModel(
      dogRepository: context.injected<DogRepository>(),
    )..addListener(_onViewModelInitialized);
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_onViewModelInitialized)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Breeds')),
      body: TaskBuilder(
        task: _viewModel.breedList,
        loading: Center(child: CircularProgressIndicator.adaptive()),
        empty: Center(child: Text('Got no Dog breeds here')),
        builder: (context, data, _) => switch (data) {
          Ok(data: final breeds) => ListView.builder(
            itemCount: breeds.length,
            itemBuilder: (context, index) {
              final breed = breeds[index];

              return ListTile(
                key: ObjectKey(breed),
                title: Text(breed.name),
                onTap: () {
                  final subBreeds = _viewModel.getSubBreedList(breed);

                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => BreedImagesScreen(
                        breed: breed,
                        subBreedList: subBreeds,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Error(:final error) => Center(child: Text(error.toString())),
        },
      ),
    );
  }
}
