import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class ConnectionListPanel extends StatelessWidget {
  const ConnectionListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    const connections = [
      (name: 'Local Dev', host: 'localhost'),
      (name: 'Production', host: 'prod-db.internal'),
      (name: 'Staging', host: 'staging-db.internal'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(right: BorderSide(color: theme.colors.border, width: 1)),
      ),
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CONNECTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                height: 28,
                child: TextField(
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.foreground,
                  ),
                  cursorColor: theme.colors.primary,
                  decoration: InputDecoration(
                    hintText: 'Search connections...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: theme.colors.mutedForeground,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 16,
                      color: theme.colors.mutedForeground,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: theme.colors.secondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: theme.colors.border,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: theme.colors.border,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: theme.colors.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: connections
                  .map(
                    (c) => _ConnectionItem(
                      name: c.name,
                      host: c.host,
                      theme: theme,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionItem extends StatelessWidget {
  final String name;
  final String host;
  final FThemeData theme;

  const _ConnectionItem({
    required this.name,
    required this.host,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.storage_outlined,
            size: 14,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  host,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colors.mutedForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
