import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/connections/presentation/cubit/connection_cubit.dart';

import '../features/editor/presentation/pages/connection_page.dart';
import '../features/workspaces/presentation/pages/workspaces_page.dart';
import '../features/editor/presentation/widgets/app_menu_actions.dart';
import 'package:flutter/services.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return PlatformMenuBar(
          menus: [
            PlatformMenu(
              label: 'File',
              menus: [
                PlatformMenuItem(
                  label: 'Quit',
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
                  onSelected: () => AppMenuActions.quit(),
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
      },
      routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _fadePage(key: state.pageKey, child: const WorkspacesPage()),
    ),
    GoRoute(
      path: '/workspace/:id',
      redirect: (context, state) {
        final id = state.pathParameters['id'];
        if (id != null) {
          final cubit = context.read<ConnectionCubit>();
          if (cubit.state.activeWorkspaceId != id) {
            cubit.setWorkspace(id);
          }
        }
        return null;
      },
      pageBuilder: (context, state) {
        return _fadePage(key: state.pageKey, child: const ConnectionPage());
      },
    ),
      ],
    ),
  ],
);

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
