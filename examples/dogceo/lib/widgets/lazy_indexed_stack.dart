import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.clipBehavior = Clip.hardEdge,
    this.sizing = StackFit.loose,
    this.index = 0,
    this.children = const [],
  });

  /// How to align the non-positioned and partially-positioned children in the
  /// stack.
  ///
  /// Defaults to [AlignmentDirectional.topStart].
  ///
  /// See [Stack.alignment] for more information.
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// How to size the non-positioned children in the stack.
  ///
  /// Defaults to [StackFit.loose].
  ///
  /// See [Stack.fit] for more information.
  final StackFit sizing;

  /// The index of the child to show.
  final int index;

  /// The child widgets of the stack.
  ///
  /// Only the child at index [index] will be shown.
  ///
  /// See [Stack.children] for more information.
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _initializedChildren;

  @override
  void initState() {
    super.initState();

    _initializedChildren = List.filled(widget.children.length, false);
    _initializedChildren[widget.index] = true;
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    if (oldWidget.index == widget.index) return;
    super.didUpdateWidget(oldWidget);

    _initializedChildren[widget.index] = true;
  }

  @override
  void dispose() {
    _initializedChildren.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.children
        .whereIndexed((i, _) => _initializedChildren[i])
        .toList();

    int index = widget.index;

    if (index > children.length) {
      // offset index by the length of children
      index = index - children.length;
    } else if (index == children.length) {
      index -= 1;
    }

    return IndexedStack(index: index, children: children);
  }
}
