import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../domain/entities/table_data.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/table_data_cubit.dart';
import '../cubit/table_data_state.dart';

class TableDataEditor extends StatelessWidget {
  final EditorTab tab;

  const TableDataEditor({required this.tab, super.key});

  @override
  Widget build(BuildContext context) {
    final key = tab.key as TableTabKey;

    return BlocListener<TableDataCubit, TableDataState>(
      listenWhen: (previous, current) {
        final before = previous.session(key)?.feedbackNonce ?? 0;
        final after = current.session(key)?.feedbackNonce ?? 0;
        return before != after && current.session(key)?.errorMessage != null;
      },
      listener: (context, state) {
        showFToast(
          context: context,
          variant: FToastVariant.destructive,
          title: Text(state.session(key)!.errorMessage!),
        );
      },
      child: BlocSelector<TableDataCubit, TableDataState, TableDataSession?>(
        selector: (state) => state.session(key),
        builder: (context, session) {
          if (session == null ||
              (session.status == TableDataStatus.initialLoading &&
                  !session.hasRows)) {
            return const _LoadingState();
          }

          if (session.status == TableDataStatus.error && !session.hasRows) {
            return _ErrorState(tableKey: key, message: session.errorMessage);
          }

          return _TableBrowser(tableKey: key, session: session);
        },
      ),
    );
  }
}

class _TableBrowser extends StatelessWidget {
  final TableTabKey tableKey;
  final TableDataSession session;

  const _TableBrowser({required this.tableKey, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isLoading =
        session.status == TableDataStatus.pageLoading ||
        session.status == TableDataStatus.refreshing;

    return Column(
      children: [
        if (session.status == TableDataStatus.error)
          _ErrorBanner(tableKey: tableKey, message: session.errorMessage),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: session.structure == null
                    ? const SizedBox.shrink()
                    : _DataGrid(tableKey: tableKey, session: session),
              ),
              if (isLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: theme.colors.background.withValues(alpha: 0.55),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _PaginationBar(tableKey: tableKey, session: session),
      ],
    );
  }
}

class _DataGrid extends StatefulWidget {
  final TableTabKey tableKey;
  final TableDataSession session;

  const _DataGrid({required this.tableKey, required this.session});

  @override
  State<_DataGrid> createState() => _DataGridState();
}

class _DataGridState extends State<_DataGrid> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.session.structure!.columns;
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
                  child: widget.session.rows.isEmpty
                      ? const _NoRows()
                      : ListView.builder(
                          itemExtent: 34,
                          itemCount: widget.session.rows.length,
                          itemBuilder: (context, index) => _GridRow(
                            row: widget.session.rows[index],
                            widths: widths,
                            selected: widget.session.selectedRowIndex == index,
                            onTap: () => context
                                .read<TableDataCubit>()
                                .selectRow(widget.tableKey, index),
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
              child: Row(
                children: [
                  if (columns[index].isPrimaryKey) ...[
                    Icon(
                      Icons.key_outlined,
                      size: 12,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
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
            ),
        ],
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  final TableDataRow row;
  final List<double> widths;
  final bool selected;
  final VoidCallback onTap;

  const _GridRow({
    required this.row,
    required this.widths,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Material(
      color: selected ? theme.colors.secondary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            for (var index = 0; index < row.cells.length; index++)
              _GridCell(value: row.cells[index], width: widths[index]),
          ],
        ),
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
    final text = Text(
      value.display,
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
      child: value.fullText != null && value.fullText!.length > 24
          ? FTooltip(
              tipBuilder: (context, controller) => ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(value.fullText!),
              ),
              child: text,
            )
          : text,
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final TableTabKey tableKey;
  final TableDataSession session;

  const _PaginationBar({required this.tableKey, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final disabled =
        session.status == TableDataStatus.pageLoading ||
        session.status == TableDataStatus.refreshing;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              _rangeLabel(session),
              style: TextStyle(
                fontSize: 12,
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(width: 24),
            Text(
              'Rows per page',
              style: TextStyle(
                fontSize: 12,
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 76,
              child: FSelect<int>(
                items: const {'25': 25, '50': 50, '100': 100},
                size: FTextFieldSizeVariant.sm,
                enabled: !disabled,
                control: FSelectControl.lifted(
                  value: session.pageSize,
                  onChange: (value) {
                    if (value != null) {
                      context.read<TableDataCubit>().setPageSize(
                        tableKey,
                        value,
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            FButton(
              size: FButtonSizeVariant.xs,
              variant: FButtonVariant.outline,
              onPress: session.canGoPrevious
                  ? () => context.read<TableDataCubit>().previousPage(tableKey)
                  : null,
              child: const Text('Previous'),
            ),
            const SizedBox(width: 6),
            FButton(
              size: FButtonSizeVariant.xs,
              variant: FButtonVariant.outline,
              onPress: session.canGoNext
                  ? () => context.read<TableDataCubit>().nextPage(tableKey)
                  : null,
              child: const Text('Next'),
            ),
            const SizedBox(width: 6),
            FTooltip(
              tipBuilder: (context, controller) => const Text('Refresh'),
              child: FButton.icon(
                size: FButtonSizeVariant.xs,
                variant: FButtonVariant.outline,
                onPress: disabled
                    ? null
                    : () => context.read<TableDataCubit>().refresh(tableKey),
                child: const Icon(Icons.refresh, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rangeLabel(TableDataSession session) {
    if (session.totalCount == 0) return '0 of 0 records';
    return '${session.rangeStart}–${session.rangeEnd} of '
        '${_formatNumber(session.totalCount)} records';
  }

  String _formatNumber(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final TableTabKey tableKey;
  final String? message;

  const _ErrorState({required this.tableKey, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message ?? 'Failed to load table',
            style: TextStyle(fontSize: 13, color: theme.colors.destructive),
          ),
          const SizedBox(height: 12),
          FButton(
            size: FButtonSizeVariant.sm,
            onPress: () => context.read<TableDataCubit>().refresh(tableKey),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final TableTabKey tableKey;
  final String? message;

  const _ErrorBanner({required this.tableKey, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: theme.colors.destructive.withValues(alpha: 0.12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message ?? 'Failed to load table',
              style: TextStyle(fontSize: 12, color: theme.colors.destructive),
            ),
          ),
          FButton(
            size: FButtonSizeVariant.xs,
            variant: FButtonVariant.outline,
            onPress: () => context.read<TableDataCubit>().refresh(tableKey),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _NoRows extends StatelessWidget {
  const _NoRows();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No records',
        style: TextStyle(
          fontSize: 13,
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }
}
