import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class ActivityBar extends StatelessWidget {
  const ActivityBar({super.key});

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
          _ActivityIcon(icon: Icons.storage_outlined, tooltip: 'Connections'),
          _ActivityIcon(icon: Icons.table_chart_outlined, tooltip: 'Tables'),
          _ActivityIcon(icon: Icons.history_outlined, tooltip: 'History'),
          _ActivityIcon(icon: Icons.code_outlined, tooltip: 'Query'),
          const Spacer(),
          _ActivityIcon(icon: Icons.settings_outlined, tooltip: 'Settings'),
        ],
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;

  const _ActivityIcon({required this.icon, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FTooltip(
      tipBuilder: (_, _) => Text(tooltip),
      child: SizedBox(
        width: 48,
        height: 40,
        child: Center(
          child: Icon(icon, size: 20, color: theme.colors.mutedForeground),
        ),
      ),
    );
  }
}
