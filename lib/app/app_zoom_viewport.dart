import 'package:flutter/material.dart';

/// Scales layout, painting, and hit testing as one application-wide viewport.
///
/// Descendants receive the inverse logical viewport size, so responsive layout
/// describes what is actually visible after scaling.
class AppZoomViewport extends StatelessWidget {
  const AppZoomViewport({super.key, required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return child;
        }

        final physicalSize = constraints.biggest;
        final logicalSize = Size(
          physicalSize.width / scale,
          physicalSize.height / scale,
        );
        final mediaQuery = MediaQuery.maybeOf(context);
        final scaledChild = mediaQuery == null
            ? child
            : MediaQuery(
                data: mediaQuery.copyWith(size: logicalSize),
                child: child,
              );

        return SizedBox.fromSize(
          size: physicalSize,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: logicalSize.width,
              maxWidth: logicalSize.width,
              minHeight: logicalSize.height,
              maxHeight: logicalSize.height,
              child: Transform.scale(
                key: const ValueKey('app-zoom-transform'),
                scale: scale,
                alignment: Alignment.topLeft,
                child: SizedBox.fromSize(size: logicalSize, child: scaledChild),
              ),
            ),
          ),
        );
      },
    );
  }
}
