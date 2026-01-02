import 'dart:async';

import 'package:dogceo/types.dart';
import 'package:flutter/foundation.dart';

final class Task<T> extends ChangeNotifier {
  Task();
  Task.init(this._data) {
    _markHasData();
  }

  late T _data;

  T get data {
    if (!_hasData) {
      throw Exception(
        "$runtimeType: accessed `data` before it was initialized."
        "Either use `init` constructor to initalize the data during creation phase"
        "or"
        "Intialize using either `run` or `runAsync`.",
      );
    }

    return _data;
  }

  bool _running = false;
  bool get running => _running;

  bool _hasData = false;
  bool get hasData => _hasData;

  /// Keep track whether this has been disposed.
  ///
  /// Used internally to track whether this a lingering object.
  ///
  /// A Lingering Object is commonly known as something which is being
  /// held on to by some entity, even though it has already been disposed
  /// thus consuming memory and other resource.
  bool _disposed = false;

  final Map<Task, List<Callback>> _dependencyMap = {};

  /// A simple helper method to automatically synchronize [running] state of [this]
  /// with [task].
  ///
  /// Basically, it adds a listener to [task] using [addDependency] and updates [running] state
  /// of [this] whenever [task] changes.
  ///
  /// Equal states are ignored. Only updates whenever [running] defers in both [task] and [this].
  void hookRunningStateTo(Task task) =>
      task.addDependency(this, (current) => current._setRunning(task.running));

  /// [task] which depends on the state changes of this [Task].
  ///
  /// [dependencyCallback] is called with [task] everytime this [Task] is updated via [notifyListeners].
  ///
  /// It is totally upto the user to filter out and selectively choose updates and changes to get more
  /// efficient rebuilds and state updates.
  ///
  /// **Example Usage:**
  ///
  /// ```dart
  ///void someFunc() {
  ///  final breedList = Task();
  ///  final allBreedsMap = Task();
  ///
  ///  allBreedsMap.addDependency(breedList, (task) {
  ///    final isRunning = allBreedsMap.running;
  ///    final doesNotHaveBreeds = !allBreedsMap.hasData;
  ///
  ///    if (isRunning || doesNotHaveBreeds) return;
  ///
  ///    task.run(
  ///      () => switch (allBreedsMap.requireData) {
  ///        Ok(:final data) => Ok(data.keys.toList()),
  ///        Error(:final error, :final stackTrace) => Error(
  ///          error,
  ///          stackTrace: stackTrace,
  ///        ),
  ///      },
  ///    );
  ///  });
  /// }
  /// ```
  ///
  /// Whenever `_allBreedsMap` updates via [notifyListeners] provided callback is executed with `breedList`
  /// and based on filter logic and conditions inside the logic [run] is executed as a side-effect to update
  /// `breedList`.
  ///
  /// All of this basically means `breedList` depends on `allBreedsMap` to perform side-effects.
  void addDependency<R>(
    Task<R> task,
    void Function(Task<R>) dependencyCallback,
  ) {
    _checkDisposed();

    void listener() => dependencyCallback(task);

    addListener(listener);
    _dependencyMap.putIfAbsent(task, () => []).add(listener);
  }

  void run(Computation<T> computation) {
    _checkDisposed();

    _setRunning(true);
    try {
      _data = computation();
      _markHasData();
    } catch (e) {
      // TOOD: Handle errors here
      return;
    } finally {
      _setRunning(false);
    }
  }

  Future<void> runAsync(AsyncComputation<T> computation) async {
    _checkDisposed();

    _setRunning(true);
    try {
      _data = await computation();
      _markHasData();
    } catch (e) {
      // TOOD: Handle errors here
      return;
    } finally {
      _setRunning(false);
    }
  }

  void _setRunning(bool running) {
    _checkDisposed();

    if (_running == running) return;

    _running = running;
    notifyListeners();
  }

  void _markHasData({bool notify = false}) {
    _checkDisposed();

    if (_hasData) return;

    _hasData = true;

    if (notify) {
      notifyListeners();
    }
  }

  /// Should be the first verification layer for any mutating operation
  /// to ensure that no further mutation happens after disposing.
  void _checkDisposed() {
    if (!_disposed) return;

    throw Exception(
      "$runtimeType"
      "Illegal usage of Task after dispose"
      "Tasks can only read after dispose, Mutations are not allowed."
      ""
      "Consider re-initializing a new Task or evaluate the dispose order and dependencies",
    );
  }

  @override
  void dispose() {
    _disposed = true;

    if (_dependencyMap.isNotEmpty) {
      for (final entry in _dependencyMap.entries) {
        final task = entry.key;

        if (!task._disposed) {
          entry.value.map(removeListener);
        }
      }

      // Release all references for garbage collector to cleanup
      _dependencyMap.clear();
    }

    super.dispose();
  }
}
