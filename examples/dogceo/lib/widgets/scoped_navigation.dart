import 'package:flutter/material.dart';

class ScopedNavigation extends StatelessWidget {
  const ScopedNavigation({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<NavigatorState>(debugLabel: "${child.runtimeType}");

    return NavigatorPopHandler(
      onPopWithResult: (_) {
        final state = key.currentState;
        if (state != null) {
          state.pop();
        }
      },
      child: Navigator(
        key: key,
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => switch (settings.name) {
              "/" => child,
              _ => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }
}
