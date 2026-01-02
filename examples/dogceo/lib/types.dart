import 'package:dogceo/utilities/task.dart';
import 'package:flutter/widgets.dart';

/// JSON type alias representing normal [key]:[value] based JSON
typedef JSON = Map<String, dynamic>;

/// Alias for a synchronous callback
/// [T] represents the type of [data] to preserve
///
/// Used by [Task] utility class.
typedef Computation<T> = T Function();

/// Computation alias for a asynchronous callback
/// [T] represents the type of [data] to preserve
///
/// Used by [Task] utility class.
typedef AsyncComputation<T> = Future<T> Function();

/// Callback alias for anonymous function
typedef Callback = void Function();

/// Widget Builder callback alias for Task with direct data access
typedef TaskDataWidgetBuilder<T> =
    Widget Function(BuildContext context, T data, Widget? child);

/// Widget Builder callback alias for Task with the object itself for more controlled access
typedef TaskWidgetBuilder<T> =
    Widget Function(BuildContext context, Task<T> task, Widget? child);
