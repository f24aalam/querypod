import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../features/connections/presentation/cubit/connection_cubit.dart';
import '../features/connections/presentation/cubit/connection_state.dart';
import '../features/workspace/presentation/widgets/activity_bar.dart';
import '../features/workspace/presentation/widgets/status_bar.dart';

class AppShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const AppShell({required this.state, required this.child, super.key});

  ActivityBarSection _activeSection() {
    if (state.uri.path == '/') {
      return ActivityBarSection.connections;
    }

    return ActivityBarSection.tables;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ColoredBox(
      color: theme.colors.background,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                BlocBuilder<ConnectionCubit, ConnectionsState>(
                  buildWhen: (prev, curr) =>
                      prev.activeConnection?.id != curr.activeConnection?.id,
                  builder: (context, connectionState) => ActivityBar(
                    activeSection: _activeSection(),
                    canOpenWorkspace: connectionState.activeConnection != null,
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.colors.border),
          const StatusBar(),
        ],
      ),
    );
  }
}
