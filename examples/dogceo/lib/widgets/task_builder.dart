import 'package:dogceo/types.dart';
import 'package:dogceo/utilities/task.dart';
import 'package:flutter/material.dart';

abstract class TaskBuilder<T> extends StatelessWidget {
  const TaskBuilder._({super.key, required this.task, this.child});

  final Task<T> task;
  final Widget? child;

  factory TaskBuilder({
    required Task<T> task,
    required TaskDataWidgetBuilder<T> builder,
    Widget loading = const SizedBox.shrink(),
    Widget empty = const SizedBox.shrink(),
    bool transitionIndicator = false,
    Key? key,
  }) {
    return _TaskDataBuilder<T>(
      key: key,
      task: task,
      builder: builder,
      loading: loading,
      empty: empty,
      transitionIndicator: transitionIndicator,
    );
  }

  factory TaskBuilder.custom({
    Key? key,
    required Task<T> task,
    required TaskWidgetBuilder<T> builder,
    Widget? child,
  }) {
    return _CustomTaskBuilder<T>(
      key: key,
      task: task,
      builder: builder,
      child: child,
    );
  }
}

final class _TaskDataBuilder<T> extends TaskBuilder<T> {
  const _TaskDataBuilder({
    required super.task,
    required this.builder,
    super.key,
    super.child,
    required this.loading,
    required this.empty,
    required this.transitionIndicator,
  }) : super._();

  final TaskDataWidgetBuilder<T> builder;
  final Widget loading;
  final Widget empty;
  final bool transitionIndicator;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: task,
      builder: (context, child) {
        if (task.running) {
          if (!task.hasData) {
            return loading;
          }

          if (transitionIndicator) {
            return loading;
          }
        }

        if (!task.hasData) {
          return empty;
        }

        return builder(context, task.data, child);
      },
      child: child,
    );
  }
}

final class _CustomTaskBuilder<T> extends TaskBuilder<T> {
  const _CustomTaskBuilder({
    required this.builder,
    required super.task,
    super.key,
    super.child,
  }) : super._();

  final TaskWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: task,
      builder: (context, child) => builder(context, task, child),
      child: child,
    );
  }
}
