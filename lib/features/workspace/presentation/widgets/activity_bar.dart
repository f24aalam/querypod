import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

enum ActivityBarSection { connections, tables, history, query, settings }

class ActivityBar extends StatelessWidget {
  final ActivityBarSection activeSection;
  final bool canOpenWorkspace;
  final String blockedMessage;

  const ActivityBar({
    required this.activeSection,
    this.canOpenWorkspace = true,
    this.blockedMessage = 'Select a connection first',
    super.key,
  });

  void _openWorkspace(BuildContext context) {
    if (!canOpenWorkspace) {
      showFToast(
        context: context,
        variant: FToastVariant.destructive,
        title: Text(blockedMessage),
      );
      return;
    }

    context.go('/workspace');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: theme.colors.secondary,
        border: Border(right: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Column(
        children: [
          _ActivityIcon(
            icon: Icons.storage_outlined,
            tooltip: 'Connections',
            isActive: activeSection == ActivityBarSection.connections,
            onTap: () => context.go('/'),
          ),
          _ActivityIcon(
            icon: Icons.table_chart_outlined,
            tooltip: 'Tables',
            isActive: activeSection == ActivityBarSection.tables,
            onTap: () => _openWorkspace(context),
          ),
          _ActivityIcon(
            icon: Icons.history_outlined,
            tooltip: 'History',
            isActive: activeSection == ActivityBarSection.history,
            onTap: () => _openWorkspace(context),
          ),
          _ActivityIcon(
            icon: Icons.code_outlined,
            tooltip: 'Query',
            isActive: activeSection == ActivityBarSection.query,
            onTap: () => _openWorkspace(context),
          ),
          const Spacer(),
          _ActivityIcon(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            isActive: activeSection == ActivityBarSection.settings,
          ),
        ],
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
