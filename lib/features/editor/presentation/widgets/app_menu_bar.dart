import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/platform_utils.dart';
import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../cubit/connection_metadata_cubit.dart';
import 'app_menu_actions.dart';

/// Installs the native macOS menu or global desktop shortcuts around the app.
class AppMenuShell extends StatelessWidget {
  const AppMenuShell({
    super.key,
    required this.child,
    this.canTransferOverride,
  });

  final Widget child;
  final bool? canTransferOverride;

  @override
  Widget build(BuildContext context) {
    if (isMacOS) {
      final canTransfer =
          canTransferOverride ??
          (context.select<ConnectionCubit, bool>(
                (cubit) => cubit.state.activeConnection != null,
              ) &&
              context.select<ConnectionMetadataCubit, bool>(
                (cubit) => cubit.state.selectedDatabase != null,
              ));
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
            label: 'File',
            menus: [
              PlatformMenuItem(
                label: 'Import Database...',
                onSelected: canTransfer
                    ? () => AppMenuActions.importDatabase(context)
                    : null,
              ),
              PlatformMenuItem(
                label: 'Export Database...',
                onSelected: canTransfer
                    ? () => AppMenuActions.exportDatabase(context)
                    : null,
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
