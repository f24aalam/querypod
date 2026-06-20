import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../cubit/activity_cubit.dart';

class ActivityBar extends StatelessWidget {
  final bool canOpenWorkspace;
  final String blockedMessage;

  const ActivityBar({
    this.canOpenWorkspace = true,
    this.blockedMessage = 'Select a connection first',
    super.key,
  });

  void _select(BuildContext context, WorkbenchActivity activity) {
    if (activity != WorkbenchActivity.connections && !canOpenWorkspace) {
      showFToast(
        context: context,
        variant: FToastVariant.destructive,
        title: Text(blockedMessage),
      );
      return;
    }

    context.read<ActivityCubit>().select(activity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<ActivityCubit, WorkbenchActivity>(
      builder: (context, activeActivity) => Container(
        width: 48,
        decoration: BoxDecoration(
          color: theme.colors.secondary,
          border: Border(
            right: BorderSide(color: theme.colors.border, width: 1),
          ),
        ),
        child: Column(
          children: [
            _ActivityIcon(
              icon: Icons.storage_outlined,
              tooltip: 'Connections',
              isActive: activeActivity == WorkbenchActivity.connections,
              onTap: () => _select(context, WorkbenchActivity.connections),
            ),
            _ActivityIcon(
              icon: Icons.table_chart_outlined,
              tooltip: 'Tables',
              isActive: activeActivity == WorkbenchActivity.tables,
              onTap: () => _select(context, WorkbenchActivity.tables),
            ),
            _ActivityIcon(
              icon: Icons.history_outlined,
              tooltip: 'History',
              isActive: activeActivity == WorkbenchActivity.history,
              onTap: () => _select(context, WorkbenchActivity.history),
            ),
            _ActivityIcon(
              icon: Icons.code_outlined,
              tooltip: 'Query',
              isActive: activeActivity == WorkbenchActivity.query,
              onTap: () => _select(context, WorkbenchActivity.query),
            ),
            const Spacer(),
            _ActivityIcon(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              isActive: activeActivity == WorkbenchActivity.settings,
              onTap: () => _select(context, WorkbenchActivity.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback? onTap;

  const _ActivityIcon({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FTooltip(
      tipBuilder: (_, _) => Text(tooltip),
      child: Material(
        color: isActive ? theme.colors.background : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 40,
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: isActive
                    ? theme.colors.foreground
                    : theme.colors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
