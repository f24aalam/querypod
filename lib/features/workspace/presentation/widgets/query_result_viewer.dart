import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../domain/entities/query_result.dart';
import '../../domain/entities/table_data.dart';

class QueryResultViewer extends StatelessWidget {
  final List<QueryResult> results;

  const QueryResultViewer({required this.results, super.key});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Container(
        color: context.theme.colors.background,
        padding: const EdgeInsets.all(16),
        child: Text(
          'No results to display.',
          style: TextStyle(color: context.theme.colors.mutedForeground),
        ),
      );
    }

    if (results.length == 1) {
      return _SingleResultViewer(result: results.first);
    }

    return FTabs(
      expands: true,
      scrollable: true,
      children: [
        for (var i = 0; i < results.length; i++)
          FTabEntry(
            label: Text('Result ${i + 1}'),
            child: _SingleResultViewer(result: results[i]),
          ),
      ],
    );
  }
}

class _SingleResultViewer extends StatelessWidget {
  final QueryResult result;

  const _SingleResultViewer({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    if (result.errorMessage != null) {
      return Container(
        color: theme.colors.background,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error executing query',
              style: TextStyle(
                color: theme.colors.destructive,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.errorMessage!,
              style: TextStyle(
                color: theme.colors.foreground,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    if (result.structure == null) {
      return Container(
        color: theme.colors.background,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Query executed successfully in ${result.queryDuration.inMilliseconds}ms.\nNo rows returned.',
          style: TextStyle(color: theme.colors.mutedForeground),
        ),
      );
    }

    return Container(
      color: theme.colors.background,
      child: Column(
        children: [
          Expanded(child: _ResultGrid(result: result)),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              border: Border(
                top: BorderSide(color: theme.colors.border, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${result.rows.length} rows',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const Spacer(),
                Text(
                  'Execution time: ${result.queryDuration.inMilliseconds}ms',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultGrid extends StatefulWidget {
  final QueryResult result;

  const _ResultGrid({required this.result});

  @override
  State<_ResultGrid> createState() => _ResultGridState();
}

class _ResultGridState extends State<_ResultGrid> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.result.structure!.columns;
    final widths = columns.map(_columnWidth).toList();
    final totalWidth = widths.fold<double>(0, (sum, width) => sum + width);

    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontal,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth < constraints.maxWidth
                ? constraints.maxWidth
                : totalWidth,
            height: constraints.maxHeight,
            child: Column(
              children: [
                _HeaderRow(columns: columns, widths: widths),
                Expanded(
                  child: ListView.builder(
                    itemExtent: 34,
                    itemCount: widget.result.rows.length,
                    itemBuilder: (context, index) => _GridRow(
                      rowIndex: index,
                      row: widget.result.rows[index],
                      widths: widths,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _columnWidth(TableDataColumn column) {
    final nameWidth = column.name.length * 8.0 + 36;
    final dataWidth = column.length.clamp(8, 28) * 7.0 + 24;
    return (nameWidth > dataWidth ? nameWidth : dataWidth).clamp(120, 280);
  }
}

class _HeaderRow extends StatelessWidget {
  final List<TableDataColumn> columns;
  final List<double> widths;

  const _HeaderRow({required this.columns, required this.widths});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      height: 34,
      color: theme.colors.secondary,
      child: Row(
        children: [
          for (var index = 0; index < columns.length; index++)
            Container(
              width: widths[index],
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: theme.colors.border, width: 1),
                  bottom: BorderSide(color: theme.colors.border, width: 1),
                ),
              ),
              child: Text(
                columns[index].name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  final int rowIndex;
  final TableDataRow row;
  final List<double> widths;

  const _GridRow({
    required this.rowIndex,
    required this.row,
    required this.widths,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        children: [
          for (var index = 0; index < row.cells.length; index++)
            _GridCell(
              value: row.cells[index],
              width: widths[index],
            ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  final TableCellValue value;
  final double width;

  const _GridCell({required this.value, required this.width});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final displayText = value.display;
    final fullText = value.fullText;
    final text = Text(
      displayText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontStyle: value.kind == TableCellKind.nullValue
            ? FontStyle.italic
            : FontStyle.normal,
        color: value.kind == TableCellKind.nullValue
            ? theme.colors.mutedForeground
            : theme.colors.foreground,
      ),
    );

    return Container(
      width: width,
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colors.border, width: 1),
          bottom: BorderSide(color: theme.colors.border, width: 0.5),
        ),
      ),
      child: fullText != null && fullText.length > 24
          ? FTooltip(
              tipBuilder: (context, controller) => ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(fullText),
              ),
              child: text,
            )
          : text,
    );
  }
}
