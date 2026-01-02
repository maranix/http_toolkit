import 'package:flutter/widgets.dart';

class _InjectorDelegate<T> extends InheritedWidget {
  const _InjectorDelegate({
    super.key,
    required this.dependency,
    required super.child,
  });

  final T dependency;

  static T of<T>(BuildContext context) =>
      context.findAncestorWidgetOfExactType<_InjectorDelegate<T>>()!.dependency;

  static T? maybeOf<T>(BuildContext context) =>
      context.findAncestorWidgetOfExactType<_InjectorDelegate<T>>()?.dependency;

  @override
  bool updateShouldNotify(_InjectorDelegate<T> oldWidget) {
    if (identical(dependency, oldWidget.dependency)) return false;

    return dependency != oldWidget.dependency;
  }
}

class Injector<T> extends StatefulWidget {
  const Injector({
    super.key,
    required this.builder,
    required this.child,
    this.dispose,
  });

  final T Function(BuildContext context) builder;
  final Widget child;
  final void Function(T)? dispose;

  static T of<T>(BuildContext context) => _InjectorDelegate.of(context);

  static T? maybeOf<T>(BuildContext context) =>
      _InjectorDelegate.maybeOf(context);

  @override
  State<Injector<T>> createState() => _Injector<T>();
}

class _Injector<T> extends State<Injector<T>> {
  late final T _dep;

  @override
  void initState() {
    super.initState();

    _dep = widget.builder(context);
  }

  @override
  void dispose() {
    widget.dispose?.call(_dep);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InjectorDelegate(dependency: _dep, child: widget.child);
  }
}

extension InjectorX on BuildContext {
  T injected<T>() => _InjectorDelegate.of(this);

  T maybeInjected<T>() => _InjectorDelegate.maybeOf(this);
}
