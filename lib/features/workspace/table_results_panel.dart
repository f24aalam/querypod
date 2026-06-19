import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class TableResultsPanel extends StatelessWidget {
  const TableResultsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    const headers = ['id', 'name', 'email', 'created_at'];
    const rows = [
      ['1', 'Alice Johnson', 'alice@example.com', '2024-01-15'],
      ['2', 'Bob Smith', 'bob@example.com', '2024-02-20'],
      ['3', 'Carol Davis', 'carol@example.com', '2024-03-10'],
      ['4', 'Dan Wilson', 'dan@example.com', '2024-04-05'],
      ['5', 'Eve Brown', 'eve@example.com', '2024-05-12'],
    ];

    const flexes = [1, 2, 2, 2];

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
                  'users',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '5 rows',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          _HeaderRow(headers: headers, theme: theme, flexes: flexes),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: rows
                  .map(
                    (row) =>
                        _DataRow(values: row, theme: theme, flexes: flexes),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<String> headers;
  final FThemeData theme;
  final List<int> flexes;

  const _HeaderRow({
    required this.headers,
    required this.theme,
    required this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.secondary,
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < headers.length; i++)
            Expanded(
              flex: flexes[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  headers[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final List<String> values;
  final FThemeData theme;
  final List<int> flexes;

  const _DataRow({
    required this.values,
    required this.theme,
    required this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              flex: flexes[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  values[i],
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
