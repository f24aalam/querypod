import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import '../../../../core/platform_utils.dart';
import 'app_menu_actions.dart';

class AppMenuBar extends StatelessWidget {
  const AppMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show on non-macOS desktop platforms
    if (isMacOS) return const SizedBox.shrink();

    final theme = context.theme;

    return Container(
      height: 30,
      color: theme.colors.background,
      child: MenuBar(
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
      ),
    );
  }
}
