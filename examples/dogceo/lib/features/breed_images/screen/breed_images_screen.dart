import 'package:dogceo/features/breed_images/view_model/breed_images_view_model.dart';
import 'package:dogceo/repositories/models/models.dart';
import 'package:dogceo/repositories/repositories.dart';
import 'package:dogceo/utilities/utilities.dart';
import 'package:dogceo/widgets/widgets.dart';
import 'package:flutter/material.dart';

class BreedImagesScreen extends StatefulWidget {
  const BreedImagesScreen({
    super.key,
    required this.breed,
    this.subBreedList = const [],
  });

  final Breed breed;
  final List<SubBreed> subBreedList;

  @override
  State<BreedImagesScreen> createState() => _BreedImagesScreenState();
}

class _BreedImagesScreenState extends State<BreedImagesScreen> {
  late final BreedImagesViewModel _viewModel;

  void _onViewModelInitialize() {
    _viewModel.getBreedImage();
  }

  @override
  void initState() {
    super.initState();

    _viewModel = BreedImagesViewModel(
      repository: context.injected<DogRepository>(),
      breed: widget.breed,
    )..addListener(_onViewModelInitialize);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelInitialize);
    _viewModel.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.breed.name)),
      body: Column(
        mainAxisAlignment: .center,
        crossAxisAlignment: .stretch,
        spacing: 16,
        children: [
          _SubBreedFilterList(
            key: Key("${widget.breed.slug}_SubBreedFilterList"),
            breeds: widget.subBreedList,
            viewModel: _viewModel,
          ),
          _RandomImageSlideShow(
            key: Key("${widget.breed.slug}_RandomImageSlideShow"),
            viewModel: _viewModel,
          ),
        ],
      ),
    );
  }
}

class _SubBreedFilterList extends StatelessWidget {
  const _SubBreedFilterList({
    super.key,
    required this.breeds,
    required this.viewModel,
  });

  final List<SubBreed> breeds;
  final BreedImagesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (breeds.isEmpty) {
      return const SizedBox.shrink();
    }

    return TaskBuilder(
      task: viewModel.selectedSubBreed,
      builder: (context, selectedSubBreed, _) {
        return SizedBox(
          height: 50,
          child: ListView.separated(
            padding: .symmetric(horizontal: 4),
            scrollDirection: .horizontal,
            itemCount: breeds.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              if (index == 0) {
                return FilterChip(
                  label: Text('All'),
                  selected: selectedSubBreed == null,
                  onSelected: (selected) {
                    viewModel.selectSubBreed(null);
                  },
                );
              }

              final breed = breeds[index - 1]; // 0 is reserved for `All` option
              return FilterChip(
                label: Text(breed.name),
                selected: selectedSubBreed == breed,
                onSelected: (selected) {
                  viewModel.selectSubBreed(breed);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _RandomImageSlideShow extends StatelessWidget {
  const _RandomImageSlideShow({super.key, required this.viewModel});

  final BreedImagesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return TaskBuilder(
      task: viewModel.image,
      loading: CircularProgressIndicator.adaptive(),
      builder: (context, data, _) {
        return switch (data) {
          Ok(data: final dog) => Expanded(
            child: NetworkPhoto(url: dog.imageURL),
          ),
          Error(:final error) => Center(
            child: Text('Something went wrong: ${error.toString()}'),
          ),
        };
      },
    );
  }
}
