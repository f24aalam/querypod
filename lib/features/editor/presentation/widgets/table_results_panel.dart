import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../cubit/connection_metadata_state.dart';
import '../cubit/connection_metadata_cubit.dart';

class TableResultsPanel extends StatelessWidget {
  const TableResultsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<ConnectionMetadataCubit, ConnectionMetadataState>(
      builder: (context, state) {
        return Container(
          color: theme.colors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.colors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: 14,
                      color: theme.colors.foreground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.selectedTable?.name ?? 'No table selected',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                    if (state.selectedDatabase != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        state.selectedDatabase!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.selectedTable == null
                          ? 'Select a table to start browsing data'
                          : 'Table preview coming soon',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
