import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isLoading =
        session.status == TableDataStatus.pageLoading ||
        session.status == TableDataStatus.refreshing;

    return Column(
      children: [
        _TableActionBar(tableKey: tableKey, session: session),
        if (session.status == TableDataStatus.error)
          _ErrorBanner(tableKey: tableKey, message: session.errorMessage),
        Expanded(
          child: _TableContent(
            tableKey: tableKey,
            session: session,
            isLoading: isLoading,
          ),
        ),
        _PaginationBar(tableKey: tableKey, session: session),
      ],
    );
  }
}

class _TableContent extends StatelessWidget {
  final TableTabKey tableKey;
  final TableDataSession session;
  final bool isLoading;

  const _TableContent({
    required this.tableKey,
    required this.session,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final grid = _GridWithLoading(
      tableKey: tableKey,
      session: session,
      isLoading: isLoading,
    );
    final selectedIndex = session.singleSelectedRowIndex;
    final showRowDetail =
        selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < session.rows.length &&
        session.structure != null;
    final showBatchInspector = session.selectionCount > 1;
    final showTableStructure = session.isShowingStructure && session.structure != null;

    if (!showRowDetail && !showBatchInspector && !showTableStructure) return grid;

    return FResizable(
      axis: Axis.horizontal,
      children: [
        FResizableRegion.flex(
          flex: 1,
          minFlex: 1,
          builder: (context, data, child) => child!,
          child: grid,
        ),
        FResizableRegion.fixed(
          extent: 320,
          minExtent: 240,
          builder: (context, data, child) => child!,
          child: showTableStructure
              ? _TableStructurePanel(tableKey: tableKey, session: session)
              : showBatchInspector
                  ? _BatchInspector(tableKey: tableKey, session: session)
                  : _RowDetailPanel(
                      tableKey: tableKey,
                      columns: session.structure!.columns,
                      row: session.rows[selectedIndex!],
                      rowNumber: session.rangeStart + selectedIndex,
                    ),
        ),
      ],
    );
  }
}

class _TableStructurePanel extends StatelessWidget {
  final TableTabKey tableKey;
  final TableDataSession session;

  const _TableStructurePanel({required this.tableKey, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final columns = session.structure!.columns;
    final indexes = session.structure!.indexes;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
      ),
      child: Column(
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colors.foreground,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Table Structure',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close table structure',
                  padding: EdgeInsets.zero,
                  splashRadius: 12,
                  onPressed: () =>
                      context.read<TableDataCubit>().hideTableStructure(tableKey),
                  icon: Icon(
                    Icons.close,
                    size: 14,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FTabs(
              expands: true,
              style: const FTabsStyleDelta.delta(
                decoration: DecorationDelta.boxDelta(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              children: [
                FTabEntry(
                  label: Text('Columns (${columns.length})', style: const TextStyle(fontSize: 12)),
                  child: _buildColumns(context, columns),
                ),
                FTabEntry(
                  label: Text('Indexes (${indexes.length})', style: const TextStyle(fontSize: 12)),
                  child: _buildIndexes(context, indexes),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumns(BuildContext context, List<TableDataColumn> columns) {
    final theme = context.theme;
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: columns.length,
      itemBuilder: (context, index) {
        final column = columns[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              if (column.isPrimaryKey) ...[
                Icon(
                  Icons.key_outlined,
                  size: 14,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(width: 8),
              ] else ...[
                const SizedBox(width: 22),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      column.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${column.databaseType}${column.length > 0 ? '(${column.length})' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    if (column.foreignKey != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colors.secondary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link, size: 10, color: theme.colors.foreground),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${column.foreignKey!.targetTable}(${column.foreignKey!.targetColumn})',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colors.foreground,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndexes(BuildContext context, List<TableIndex> indexes) {
    final theme = context.theme;
    if (indexes.isEmpty) {
      return Center(
        child: Text(
          'No indexes found',
          style: TextStyle(fontSize: 13, color: theme.colors.mutedForeground),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: indexes.length,
      itemBuilder: (context, index) {
        final idx = indexes[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colors.border, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      idx.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                  if (idx.isPrimaryKey || idx.isUnique) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: idx.isPrimaryKey ? Colors.amber.withValues(alpha: 0.2) : theme.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: idx.isPrimaryKey ? Colors.amber.shade700 : theme.colors.primary,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        idx.isPrimaryKey ? 'PK' : 'UNIQUE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: idx.isPrimaryKey ? Colors.amber.shade700 : theme.colors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                idx.columns.join(', '),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridWithLoading extends StatelessWidget {
  final TableTabKey tableKey;
  final TableDataSession session;
  final bool isLoading;

  const _GridWithLoading({
    required this.tableKey,
    required this.session,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Stack(
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
    );
  }
}

class _RowDetailPanel extends StatelessWidget {
  final TableTabKey tableKey;
  final List<TableDataColumn> columns;
  final TableDataRow row;
  final int rowNumber;

  const _RowDetailPanel({
    required this.tableKey,
    required this.columns,
    required this.row,
    required this.rowNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(left: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.only(left: 12, right: 4),
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
                Expanded(
                  child: Text(
                    'Row $rowNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close row details',
                  padding: EdgeInsets.zero,
                  splashRadius: 12,
                  onPressed: () =>
                      context.read<TableDataCubit>().clearSelection(tableKey),
                  icon: Icon(
                    Icons.close,
                    size: 14,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: columns.length,
              itemBuilder: (context, index) => _RowDetailField(
                column: columns[index],
                value: row.cells[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchInspector extends StatelessWidget {
  final TableTabKey tableKey;
  final TableDataSession session;

  const _BatchInspector({required this.tableKey, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(left: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colors.border, width: 1),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              'Batch selection',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colors.foreground,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.selectionCount} rows selected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _summary(session),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 14),
                _InspectorMetric(
                  label: 'Staged cell edits',
                  value: session.stagedCellEdits.length.toString(),
                ),
                const SizedBox(height: 8),
                _InspectorMetric(
                  label: 'Rows marked for delete',
                  value: session.stagedDeletedRowIndexes.length.toString(),
                ),
                const SizedBox(height: 16),
                FButton(
                  size: FButtonSizeVariant.xs,
                  variant: FButtonVariant.outline,
                  onPress: () =>
                      context.read<TableDataCubit>().clearSelection(tableKey),
                  child: const Text('Clear selection'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _summary(TableDataSession session) {
    final edits = session.stagedCellEdits.length;
    final deletes = session.stagedDeletedRowIndexes.length;
    if (edits == 0 && deletes == 0) {
      return 'Use Ctrl/Cmd-click to toggle rows and Shift-click to select a range on this page.';
    }
    return '${session.selectionCount} rows selected, '
        '$edits staged cell edits, $deletes rows marked for delete.';
  }
}

class _InspectorMetric extends StatelessWidget {
  final String label;
  final String value;

  const _InspectorMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
      ],
    );
  }
}

class _RowDetailField extends StatelessWidget {
  final TableDataColumn column;
  final TableCellValue value;

  const _RowDetailField({required this.column, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final displayedValue = value.fullText ?? value.display;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (column.isPrimaryKey) ...[
                Icon(
                  Icons.key_outlined,
                  size: 11,
                  color: theme.colors.mutedForeground,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  column.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
              Text(
                column.databaseType,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              displayedValue,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontStyle: value.kind == TableCellKind.nullValue
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: value.kind == TableCellKind.nullValue
                    ? theme.colors.mutedForeground
                    : theme.colors.foreground,
              ),
            ),
          ),
        ],
      ),
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
                            tableKey: widget.tableKey,
                            rowIndex: index,
                            row: widget.session.rows[index],
                            widths: widths,
                            selected: widget.session.selectedRowIndexes
                                .contains(index),
                            activeEdit: widget.session.activeCellEdit,
                            stagedEdits: widget.session.stagedCellEdits,
                            stagedDelete: widget.session.stagedDeletedRowIndexes
                                .contains(index),
                            editable: widget.session.isEditable,
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
                  if (columns[index].foreignKey != null) ...[
                    Icon(
                      Icons.link,
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
  final TableTabKey tableKey;
  final int rowIndex;
  final TableDataRow row;
  final List<double> widths;
  final bool selected;
  final TableCellEdit? activeEdit;
  final Map<TableCellCoordinate, TableCellEdit> stagedEdits;
  final bool stagedDelete;
  final bool editable;

  const _GridRow({
    required this.tableKey,
    required this.rowIndex,
    required this.row,
    required this.widths,
    required this.selected,
    required this.activeEdit,
    required this.stagedEdits,
    required this.stagedDelete,
    required this.editable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FContextMenu(
      menuBuilder: (context, controller, menu) => [
        FItemGroup(
          children: [
            FItem(
              variant: FItemVariant.destructive,
              enabled: editable,
              prefix: const Icon(Icons.delete_outline, size: 14),
              title: const Text('Delete selection'),
              onPress: editable
                  ? () {
                      controller.hide();
                      context.read<TableDataCubit>().stageDeleteForRow(
                        tableKey,
                        rowIndex,
                      );
                    }
                  : null,
            ),
          ],
        ),
      ],
      child: Material(
        color: stagedDelete
            ? theme.colors.destructive.withValues(alpha: 0.18)
            : selected
            ? theme.colors.secondary
            : Colors.transparent,
        child: Row(
          children: [
            for (var index = 0; index < row.cells.length; index++)
              _GridCell(
                rowIndex: rowIndex,
                columnIndex: index,
                value: row.cells[index],
                width: widths[index],
                activeEdit:
                    activeEdit?.rowIndex == rowIndex &&
                        activeEdit?.columnIndex == index
                    ? activeEdit
                    : null,
                stagedEdit:
                    stagedEdits[TableCellCoordinate(
                      rowIndex: rowIndex,
                      columnIndex: index,
                    )],
                deleted: stagedDelete,
                onActivate: (event) {
                  if ((event.buttons & kPrimaryMouseButton) == 0) return;
                  final keyboard = HardwareKeyboard.instance;
                  context.read<TableDataCubit>().activateCell(
                    tableKey,
                    rowIndex,
                    index,
                    toggleSelection:
                        keyboard.isControlPressed || keyboard.isMetaPressed,
                    extendSelection: keyboard.isShiftPressed,
                  );
                },
                onChanged: (value) => context
                    .read<TableDataCubit>()
                    .updateCellDraft(tableKey, value),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  final int rowIndex;
  final int columnIndex;
  final TableCellValue value;
  final double width;
  final TableCellEdit? activeEdit;
  final TableCellEdit? stagedEdit;
  final bool deleted;
  final ValueChanged<PointerDownEvent> onActivate;
  final ValueChanged<String> onChanged;

  const _GridCell({
    required this.rowIndex,
    required this.columnIndex,
    required this.value,
    required this.width,
    required this.activeEdit,
    required this.stagedEdit,
    required this.deleted,
    required this.onActivate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final pendingEdit = stagedEdit?.isDirty ?? false;
    final displayText = stagedEdit?.draftText ?? value.display;
    final fullText = stagedEdit?.draftText ?? value.fullText;
    final text = Text(
      displayText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontStyle: value.kind == TableCellKind.nullValue && stagedEdit == null
            ? FontStyle.italic
            : FontStyle.normal,
        color: value.kind == TableCellKind.nullValue && stagedEdit == null
            ? theme.colors.mutedForeground
            : deleted
            ? theme.colors.destructive
            : theme.colors.foreground,
        decoration: deleted ? TextDecoration.lineThrough : null,
      ),
    );

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: activeEdit == null ? onActivate : null,
      child: Container(
        width: width,
        height: 34,
        padding: activeEdit == null
            ? const EdgeInsets.symmetric(horizontal: 10)
            : EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: pendingEdit && !deleted
              ? Colors.amber.withValues(alpha: 0.16)
              : null,
          border: Border(
            right: BorderSide(color: theme.colors.border, width: 1),
            bottom: BorderSide(color: theme.colors.border, width: 0.5),
          ),
        ),
        child: activeEdit != null
            ? _CellTextField(edit: activeEdit!, onChanged: onChanged)
            : fullText != null && fullText.length > 24
            ? FTooltip(
                tipBuilder: (context, controller) => ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(fullText),
                ),
                child: text,
              )
            : text,
      ),
    );
  }
}

class _CellTextField extends StatefulWidget {
  final TableCellEdit edit;
  final ValueChanged<String> onChanged;

  const _CellTextField({required this.edit, required this.onChanged});

  @override
  State<_CellTextField> createState() => _CellTextFieldState();
}

class _CellTextFieldState extends State<_CellTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.edit.draftText);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant _CellTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.edit.draftText) {
      _controller.value = TextEditingValue(
        text: widget.edit.draftText,
        selection: TextSelection.collapsed(
          offset: widget.edit.draftText.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final borderColor = Colors.amber.shade700;
    return TextField(
      key: ValueKey<(String, int, int)>((
        'table-cell-editor',
        widget.edit.rowIndex,
        widget.edit.columnIndex,
      )),
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      expands: true,
      minLines: null,
      maxLines: null,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(fontSize: 12, color: theme.colors.foreground),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.amber.withValues(alpha: 0.16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
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
        session.status == TableDataStatus.refreshing ||
        session.isCommittingChanges;

    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!session.isEditable) ...[
                    Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Read-only: no primary key',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const SizedBox(width: 16),
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
                ],
              ),
            ),
          ),
          if (session.hasPendingChanges || session.hasSelection)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (session.hasSelection) ...[
                    Text(
                      '${session.selectionCount} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    if (session.hasPendingChanges) const SizedBox(width: 12),
                  ],
                  if (session.hasPendingChanges) ...[
                    FButton(
                      size: FButtonSizeVariant.xs,
                      variant: session.hasPendingDeletes
                          ? FButtonVariant.destructive
                          : FButtonVariant.primary,
                      onPress: session.isCommittingChanges
                          ? null
                          : () => context
                                .read<TableDataCubit>()
                                .commitPendingChanges(tableKey),
                      child: Text(
                        session.isCommittingChanges ? 'Committing…' : 'Commit',
                      ),
                    ),
                    const SizedBox(width: 6),
                    FButton(
                      size: FButtonSizeVariant.xs,
                      variant: FButtonVariant.outline,
                      onPress: session.isCommittingChanges
                          ? null
                          : () => context
                                .read<TableDataCubit>()
                                .clearPendingChanges(tableKey),
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              reverse: true,
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _rangeLabel(session),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FButton(
                    size: FButtonSizeVariant.xs,
                    variant: FButtonVariant.outline,
                    onPress: session.canGoPrevious
                        ? () => context.read<TableDataCubit>().previousPage(
                            tableKey,
                          )
                        : null,
                    child: const Text('Previous'),
                  ),
                  const SizedBox(width: 6),
                  FButton(
                    size: FButtonSizeVariant.xs,
                    variant: FButtonVariant.outline,
                    onPress: session.canGoNext
                        ? () =>
                              context.read<TableDataCubit>().nextPage(tableKey)
                        : null,
                    child: const Text('Next'),
                  ),
                  const SizedBox(width: 6),
                  FTooltip(
                    tipBuilder: (context, controller) =>
                        const Text('Table Structure'),
                    child: FButton.icon(
                      size: FButtonSizeVariant.xs,
                      variant: session.isShowingStructure
                          ? FButtonVariant.secondary
                          : FButtonVariant.outline,
                      onPress: disabled
                          ? null
                          : () {
                              final cubit = context.read<TableDataCubit>();
                              if (session.isShowingStructure) {
                                cubit.hideTableStructure(tableKey);
                              } else {
                                cubit.showTableStructure(tableKey);
                              }
                            },
                      child: const Icon(Icons.info_outline, size: 14),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FTooltip(
                    tipBuilder: (context, controller) => const Text('Refresh'),
                    child: FButton.icon(
                      size: FButtonSizeVariant.xs,
                      variant: FButtonVariant.outline,
                      onPress: disabled
                          ? null
                          : () => context.read<TableDataCubit>().refresh(
                              tableKey,
                            ),
                      child: const Icon(Icons.refresh, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _TableActionBar extends StatefulWidget {
  final TableTabKey tableKey;
  final TableDataSession session;

  const _TableActionBar({required this.tableKey, required this.session});

  @override
  State<_TableActionBar> createState() => _TableActionBarState();
}

class _TableActionBarState extends State<_TableActionBar> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.session.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _TableActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.session.searchQuery != _searchController.text) {
      _searchController.text = widget.session.searchQuery ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<TableDataCubit>().setSearchQuery(widget.tableKey, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(bottom: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: _searchController,
                onChange: (value) => _onSearchChanged(value.text),
              ),
              hint: 'Search all columns...',
              maxLines: 1,
              size: FTextFieldSizeVariant.sm,
              clearable: (value) => value.text.isNotEmpty,
            ),
          ),
          const SizedBox(width: 8),
          FTooltip(
            tipBuilder: (context, controller) => const Text('Filters'),
            child: Badge(
              isLabelVisible: widget.session.filters.isNotEmpty,
              label: Text(widget.session.filters.length.toString()),
              child: FButton.icon(
                variant: FButtonVariant.outline,
                size: FButtonSizeVariant.sm,
                onPress: () => _showFilterSheet(context),
                child: const Icon(Icons.filter_list, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final cubit = context.read<TableDataCubit>();
    final session = widget.session;
    final operators = cubit.supportedOperators(widget.tableKey);
    
    showFSheet(
      context: context,
      side: FLayout.rtl,
      builder: (sheetContext) => _FilterSheet(
        columns: session.structure?.columns ?? [],
        operators: operators,
        initialFilters: session.filters,
        onApply: (filters) {
          Navigator.of(sheetContext).pop();
          cubit.setFilters(widget.tableKey, filters);
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<TableDataColumn> columns;
  final List<String> operators;
  final List<TableFilter> initialFilters;
  final ValueChanged<List<TableFilter>> onApply;

  const _FilterSheet({
    required this.columns,
    required this.operators,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late List<_FilterFormRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialFilters.map((f) => _FilterFormRow(
      column: f.column,
      operator: f.operator,
      valueController: TextEditingController(text: f.value),
    )).toList();

    if (_rows.isEmpty) {
      _rows.add(_FilterFormRow(
        column: widget.columns.isNotEmpty ? widget.columns.first.name : '',
        operator: widget.operators.isNotEmpty ? widget.operators.first : '=',
        valueController: TextEditingController(),
      ));
    }
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row.valueController.dispose();
    }
    super.dispose();
  }

  void _addFilter() {
    setState(() {
      _rows.add(_FilterFormRow(
        column: widget.columns.isNotEmpty ? widget.columns.first.name : '',
        operator: widget.operators.isNotEmpty ? widget.operators.first : '=',
        valueController: TextEditingController(),
      ));
    });
  }

  void _removeFilter(int index) {
    setState(() {
      final removed = _rows.removeAt(index);
      removed.valueController.dispose();
    });
  }

  void _applyFilters() {
    final filters = _rows.where((row) => row.column.isNotEmpty && row.operator.isNotEmpty).map((row) => TableFilter(
      column: row.column,
      operator: row.operator,
      value: row.valueController.text,
    )).toList();
    widget.onApply(filters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: 400,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(left: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colors.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 20,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, size: 20, color: theme.colors.mutedForeground),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _rows.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == _rows.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FButton(
                      variant: FButtonVariant.outline,
                      onPress: _addFilter,
                      child: const Text('Add more'),
                    ),
                  );
                }

                final row = _rows[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: FSelect<String>(
                        items: { for (var c in widget.columns) c.name : c.name },
                        control: FSelectControl.lifted(
                          value: row.column,
                          onChange: (val) {
                            if (val != null) setState(() => row.column = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: FSelect<String>(
                        items: { for (var op in widget.operators) op : op },
                        control: FSelectControl.lifted(
                          value: row.operator,
                          onChange: (val) {
                            if (val != null) setState(() => row.operator = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FTextField(
                        control: FTextFieldControl.managed(
                          controller: row.valueController,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FButton.icon(
                      variant: FButtonVariant.outline,
                      onPress: () => _removeFilter(index),
                      child: const Icon(Icons.delete_outline, size: 16),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
            ),
            child: Row(
              children: [
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => widget.onApply(const []),
                  child: const Text('Clear filter'),
                ),
                const Spacer(),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: _applyFilters,
                  child: const Text('Filter'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterFormRow {
  String column;
  String operator;
  TextEditingController valueController;

  _FilterFormRow({
    required this.column,
    required this.operator,
    required this.valueController,
  });
}
