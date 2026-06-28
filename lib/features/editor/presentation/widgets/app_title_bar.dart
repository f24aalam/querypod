import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/platform_utils.dart';
import 'app_menu_actions.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    // A unified top bar that spans the whole width.
    return Container(
      height: 32, // slightly taller for window controls
      color: theme.colors.background,
      child: Row(
        children: [
          // On macOS, leave space for traffic lights on the left
          if (isMacOS) const SizedBox(width: 80),
          
          // Menu bar (Hidden on macOS because PlatformMenuBar handles it)
          if (!isMacOS) _buildMenuBar(context, theme),

          // The flexible area that can be dragged to move the window
          Expanded(
            child: isDesktop ? const DragToMoveArea(child: SizedBox.expand()) : const SizedBox.shrink(),
          ),

          // Window Controls (Minimize, Maximize, Close)
          if (isDesktop && !isMacOS) ...[
            WindowCaptionButton.minimize(
              brightness: Theme.of(context).brightness,
              onPressed: () => windowManager.minimize(),
            ),
            WindowCaptionButton.maximize(
              brightness: Theme.of(context).brightness,
              onPressed: () async {
                bool isMaximized = await windowManager.isMaximized();
                if (isMaximized) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            WindowCaptionButton.close(
              brightness: Theme.of(context).brightness,
              onPressed: AppMenuActions.quit, // Use our existing action to quit
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuBar(BuildContext context, FThemeData theme) {
    return MenuBar(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(theme.colors.background),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      children: [
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: AppMenuActions.quit,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
              child: Text('Quit', style: TextStyle(color: theme.colors.foreground)),
            ),
          ],
          child: Text('File', style: TextStyle(color: theme.colors.foreground)),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: () => AppMenuActions.changeWorkspace(context),
              child: Text('Change Workspace', style: TextStyle(color: theme.colors.foreground)),
            ),
          ],
          child: Text('Workspace', style: TextStyle(color: theme.colors.foreground)),
        ),
      ],
    );
  }
}
