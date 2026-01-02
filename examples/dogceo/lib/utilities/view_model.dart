import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class ViewModel extends ChangeNotifier {
  ViewModel() {
    init();
  }

  bool _initialized = false;
  bool get initialized => _initialized;

  /// Automatically called when the instance is created.
  ///
  /// call to `super.init` must be done at the very end.
  ///
  /// Any further mutation operations should be done based on [initialized] value.
  @mustCallSuper
  FutureOr<void> init() {
    _initialized = true;

    return Future.microtask(notifyListeners);
  }

  @override
  @mustCallSuper
  FutureOr<void> dispose() {
    if (!_initialized) {
      throw Exception(
        "Unable to dipose un-initialized ViewModel"
        ""
        "Make sure to call `super.init()` at the end incase `init()` was overriden.",
      );
    }

    super.dispose();
  }
}
