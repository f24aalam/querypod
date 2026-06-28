import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class SidebarHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SidebarHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.only(left: 12, right: 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      height: 34,
      padding: padding,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
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
          ?trailing,
        ],
      ),
    );
  }
}
