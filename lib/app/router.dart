import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import '../features/connections/presentation/pages/connections_page.dart';
import '../features/workspace/presentation/pages/workspace_page.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(state: state, child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              _fadePage(key: state.pageKey, child: const ConnectionsPage()),
        ),
        GoRoute(
          path: '/workspace',
          pageBuilder: (context, state) =>
              _fadePage(key: state.pageKey, child: const WorkspacePage()),
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
