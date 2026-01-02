import 'package:flutter/material.dart'
    show Durations, CircularProgressIndicator;
import 'package:flutter/widgets.dart';

class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({
    super.key,
    required this.url,
    this.resizeForOverflow = true,
  });

  final String url;
  final bool resizeForOverflow;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final size = MediaQuery.sizeOf(context);

    final imageWidth = switch (resizeForOverflow) {
      true => size.width * dpr,
      false => null,
    };

    return Image.network(
      url,
      width: imageWidth,
      cacheWidth: imageWidth?.toInt(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }

        return AnimatedSwitcher(
          duration: Durations.extralong4,
          switchInCurve: Curves.easeInToLinear,
          switchOutCurve: Curves.easeOutExpo,
          child: frame == null ? CircularProgressIndicator.adaptive() : child,
        );
      },
    );
  }
}
