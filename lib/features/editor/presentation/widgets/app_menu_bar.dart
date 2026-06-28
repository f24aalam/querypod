import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/platform_utils.dart';
import 'app_menu_actions.dart';

/// Installs the native macOS menu or global desktop shortcuts around the app.
class AppMenuShell extends StatelessWidget {
  const AppMenuShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isMacOS) {
      return PlatformMenuBar(
        menus: [
          const PlatformMenu(
            label: 'QueryPod',
            menus: [
              PlatformMenuItemGroup(
                members: [PlatformProvidedMenuItem(type: .about)],
              ),
              PlatformMenuItemGroup(
                members: [PlatformProvidedMenuItem(type: .servicesSubmenu)],
              ),
              PlatformMenuItemGroup(
                members: [
                  PlatformProvidedMenuItem(type: .hide),
                  PlatformProvidedMenuItem(type: .hideOtherApplications),
                  PlatformProvidedMenuItem(type: .showAllApplications),
                ],
              ),
              PlatformMenuItemGroup(
                members: [PlatformProvidedMenuItem(type: .quit)],
              ),
            ],
          ),
          PlatformMenu(
            label: 'Workspace',
            menus: [
              PlatformMenuItem(
                label: 'Change Workspace',
                onSelected: () => AppMenuActions.changeWorkspace(context),
              ),
            ],
          ),
        ],
        child: child,
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
            AppMenuActions.quit,
      },
      child: child,
    );
  }
}
