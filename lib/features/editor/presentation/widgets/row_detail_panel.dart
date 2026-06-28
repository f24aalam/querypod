import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class RowDetailPanel extends StatelessWidget {
  const RowDetailPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    const fields = [
      ('id', '1'),
      ('name', 'Alice Johnson'),
      ('email', 'alice@example.com'),
      ('created_at', '2024-01-15'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(left: BorderSide(color: theme.colors.border, width: 1)),
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
            child: Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 14,
                  color: theme.colors.foreground,
                ),
                const SizedBox(width: 6),
                Text(
                  'Row Detail',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: fields
                  .map(
                    (field) => _RowField(
                      key_: field.$1,
                      value: field.$2,
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

class _RowField extends StatelessWidget {
  final String key_;
  final String value;
  final FThemeData theme;

  const _RowField({
    required this.key_,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key_,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: theme.colors.foreground),
          ),
          Divider(height: 12, thickness: 0.5, color: theme.colors.border),
        ],
      ),
    );
  }
}
