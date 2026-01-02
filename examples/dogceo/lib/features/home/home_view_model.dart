import 'dart:async';

import 'package:dogceo/utilities/utilities.dart';

final class HomeViewModel extends ViewModel {
  late final Task<int> selectedTabIndex;

  @override
  FutureOr<void> init() {
    selectedTabIndex = Task.init(1);

    super.init();
  }

  @override
  FutureOr<void> dispose() {
    selectedTabIndex.dispose();

    super.dispose();
  }

  void onTabChanged(int index) {
    selectedTabIndex.run(() => index);
  }
}
