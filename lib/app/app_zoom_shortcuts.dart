import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_cubit.dart';

/// Installs VS Code-style application zoom shortcuts for desktop platforms.
class AppZoomShortcuts extends StatelessWidget {
  const AppZoomShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    SingleActivator activate(LogicalKeyboardKey key, {bool shift = false}) =>
        SingleActivator(key, control: !isMacOS, meta: isMacOS, shift: shift);

    ThemeCubit cubit;
    try {
      cubit = context.read<ThemeCubit>();
    } on Object {
      // AppMenuShell is also useful in isolated widget tests and previews.
      return child;
    }
    return CallbackShortcuts(
      bindings: {
        activate(LogicalKeyboardKey.equal): cubit.zoomIn,
        activate(LogicalKeyboardKey.equal, shift: true): cubit.zoomIn,
        activate(LogicalKeyboardKey.add): cubit.zoomIn,
        activate(LogicalKeyboardKey.numpadAdd): cubit.zoomIn,
        activate(LogicalKeyboardKey.minus): cubit.zoomOut,
        activate(LogicalKeyboardKey.numpadSubtract): cubit.zoomOut,
        activate(LogicalKeyboardKey.digit0): cubit.resetZoom,
        activate(LogicalKeyboardKey.numpad0): cubit.resetZoom,
      },
      child: child,
    );
  }
}
