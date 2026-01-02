import 'package:dogceo/features/random_image/view_model/random_image_view_model.dart';
import 'package:dogceo/repositories/repositories.dart';
import 'package:dogceo/utilities/utilities.dart';
import 'package:dogceo/widgets/widgets.dart';

import 'package:flutter/material.dart';

class RandomImageScreen extends StatefulWidget {
  const RandomImageScreen({super.key});

  @override
  State<RandomImageScreen> createState() => _RandomImageScreenState();
}

class _RandomImageScreenState extends State<RandomImageScreen> {
  late final RandomImageViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    /// Intializes with slideshow enabled
    _viewModel = RandomImageViewModel(
      dogRepository: context.injected<DogRepository>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        spacing: 16,
        mainAxisAlignment: .end,
        children: [
          TaskBuilder(
            task: _viewModel.slideshowRunning,
            builder: (context, running, _) {
              return FloatingActionButton(
                onPressed: _viewModel.toggleSlideshow,
                child: switch (running) {
                  true => Icon(Icons.pause_rounded),
                  false => Icon(Icons.play_arrow_rounded),
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: TaskBuilder(
          task: _viewModel.randomImage,
          loading: CircularProgressIndicator.adaptive(),
          empty: Center(child: Text('Got no Dog here')),
          builder: (context, data, _) => switch (data) {
            Ok(:final data) => Column(
              spacing: 16,
              children: [Expanded(child: NetworkPhoto(url: data.imageURL))],
            ),
            Error(:final error) => Center(child: Text(error.toString())),
          },
        ),
      ),
    );
  }
}
