import 'package:dogceo/features/breed_list/breed_list.dart';
import 'package:dogceo/features/home/home_view_model.dart';
import 'package:dogceo/features/random_image/screen/random_image_screen.dart';
import 'package:dogceo/widgets/widgets.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;
  late final List<Widget> _destinations;

  @override
  void initState() {
    super.initState();

    _viewModel = HomeViewModel();
    _destinations = List.of([
      const ScopedNavigation(child: BreedListScreen()),
      const ScopedNavigation(child: RandomImageScreen()),
    ], growable: false);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _destinations.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TaskBuilder(
        task: _viewModel.selectedTabIndex,
        builder: (context, selectedIndex, _) {
          return LazyIndexedStack(
            index: selectedIndex,
            children: _destinations,
          );
        },
      ),
      bottomNavigationBar: TaskBuilder(
        task: _viewModel.selectedTabIndex,
        builder: (context, selectedIndex, _) {
          return NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: _viewModel.onTabChanged,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.pets_rounded),
                label: 'Breeds',
              ),
              NavigationDestination(
                icon: Icon(Icons.image_rounded),
                label: 'Woof',
              ),
            ],
          );
        },
      ),
    );
  }
}
