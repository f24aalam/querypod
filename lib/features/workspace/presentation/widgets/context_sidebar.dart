import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/presentation/widgets/connection_list_panel.dart';
import '../cubit/activity_cubit.dart';
import 'table_list_panel.dart';

class ContextSidebar extends StatelessWidget {
  const ContextSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityCubit, WorkbenchActivity>(
      builder: (context, activity) {
        return switch (activity) {
          WorkbenchActivity.connections => const ConnectionListPanel(),
          WorkbenchActivity.tables => const TableListPanel(),
          WorkbenchActivity.history => const _SidebarPlaceholder(
            title: 'HISTORY',
            message: 'Query history coming soon',
          ),
          WorkbenchActivity.query => const _SidebarPlaceholder(
            title: 'QUERY',
            message: 'Query tools coming soon',
          ),
          WorkbenchActivity.settings => const _SidebarPlaceholder(
            title: 'SETTINGS',
            message: 'Settings coming soon',
          ),
        };
      },
    );
  }
}

class _SidebarPlaceholder extends StatelessWidget {
  final String title;
  final String message;

  const _SidebarPlaceholder({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(right: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colors.border, width: 1),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
