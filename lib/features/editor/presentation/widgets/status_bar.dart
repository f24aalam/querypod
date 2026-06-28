import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../../connections/presentation/cubit/connection_state.dart';
import '../cubit/connection_metadata_cubit.dart';
import '../cubit/connection_metadata_state.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/table_data_cubit.dart';
import '../cubit/table_data_state.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bgColor = theme.colors.secondary;
    final fgColor = theme.colors.secondaryForeground;
    final mutedColor = theme.colors.mutedForeground;

    return BlocBuilder<ConnectionCubit, ConnectionsState>(
      buildWhen: (prev, curr) =>
          prev.activeConnection?.name != curr.activeConnection?.name ||
          prev.activeConnection?.sessionIdentity !=
              curr.activeConnection?.sessionIdentity,
      builder: (context, connectionState) {
        return BlocBuilder<ConnectionMetadataCubit, ConnectionMetadataState>(
          buildWhen: (prev, curr) =>
              prev.selectedDatabase != curr.selectedDatabase ||
              prev.connectionSession != curr.connectionSession,
          builder: (context, workspaceState) {
            final connection = connectionState.activeConnection;
            final isConnected = connection != null;
            const connectedColor = Color(0xFF22C55E);
            final databaseName =
                isConnected &&
                    workspaceState.connectionId == connection.id &&
                    workspaceState.connectionSession ==
                        connection.sessionIdentity &&
                    workspaceState.selectedDatabase != null
                ? workspaceState.selectedDatabase!
                : (isConnected && connection.database.isNotEmpty
                      ? connection.database
                      : 'No Database');

            return Container(
              height: 34,
              color: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isConnected ? connectedColor : mutedColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? connection.name : 'Not Connected',
                    style: TextStyle(
                      fontSize: 11,
                      color: isConnected ? connectedColor : fgColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.dataset_outlined, size: 12, color: mutedColor),
                  const SizedBox(width: 4),
                  Text(
                    databaseName,
                    style: TextStyle(fontSize: 11, color: fgColor),
                  ),
                  const Spacer(),
                  const _ActiveTableStats(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ActiveTableStats extends StatelessWidget {
  const _ActiveTableStats();

  @override
  Widget build(BuildContext context) {
    final mutedColor = context.theme.colors.mutedForeground;
    return BlocSelector<EditorTabsCubit, EditorTabsState, EditorTabKey?>(
      selector: (state) => state.activeTabKey,
      builder: (context, activeKey) {
        if (activeKey is! TableTabKey) {
          return _StatsText(rows: 0, milliseconds: 0, color: mutedColor);
        }

        return BlocSelector<TableDataCubit, TableDataState, TableDataSession?>(
          selector: (state) => state.session(activeKey),
          builder: (context, session) => _StatsText(
            rows: session?.rows.length ?? 0,
            milliseconds: session?.queryDuration.inMilliseconds ?? 0,
            color: mutedColor,
          ),
        );
      },
    );
  }
}

class _StatsText extends StatelessWidget {
  final int rows;
  final int milliseconds;
  final Color color;

  const _StatsText({
    required this.rows,
    required this.milliseconds,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$rows rows', style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(width: 16),
        Text('${milliseconds}ms', style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
