import 'package:dogceo/features/home/home.dart';
import 'package:dogceo/repositories/repositories.dart';
import 'package:dogceo/widgets/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    Injector<DogRepository>(
      builder: (_) => DogRepository(),
      dispose: (r) => r.dispose(),
      child: const DogCeoApp(),
    ),
  );
}

class DogCeoApp extends StatelessWidget {
  const DogCeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomeScreen());
  }
}
