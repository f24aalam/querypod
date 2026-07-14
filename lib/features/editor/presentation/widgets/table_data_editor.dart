import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../domain/entities/table_data.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/table_data_cubit.dart';
import '../cubit/table_data_state.dart';
import '../../../../core/keyboard/keyboard_shortcuts.dart';

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
                  session.structure == null)) {
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
    final showLoadingLine =
        session.status == TableDataStatus.initialLoading ||
        session.status == TableDataStatus.pageLoading ||
        session.status == TableDataStatus.refreshing;

    return Column(
      children: [
        if (showLoadingLine) const _TableLoadingLine(),
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

class _TableLoadingLine extends StatelessWidget {
  const _TableLoadingLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey('active-table-loading-line'),
      height: 2,
      width: double.infinity,
      child: LinearProgressIndicator(minHeight: 2),
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
    final showForeignPreview = session.foreignRowPreview != null;
    final isFetchingForeignRow = session.isFetchingForeignRow;
    final showRowDetail =
        selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < session.rows.length &&
        session.structure != null;
    final showBatchInspector = session.selectionCount > 1;
    final showTableStructure =
        session.isShowingStructure && session.structure != null;

    if (!isFetchingForeignRow &&
        !showForeignPreview &&
        !showRowDetail &&
        !showBatchInspector &&
        !showTableStructure) {
      return grid;
    }

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
          child: isFetchingForeignRow
              ? Container(
                  decoration: BoxDecoration(
                    color: context.theme.colors.background,
                    border: Border(
                      left: BorderSide(
                        color: context.theme.colors.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : showForeignPreview
              ? _ForeignRowPreviewPanel(tableKey: tableKey, session: session)
              : showTableStructure
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
      decoration: BoxDecoration(color: theme.colors.background),
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
                  onPressed: () => context
                      .read<TableDataCubit>()
                      .hideTableStructure(tableKey),
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
                  label: Text(
                    'Columns (${columns.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  child: _buildColumns(context, columns),
                ),
                FTabEntry(
                  label: Text(
                    'Indexes (${indexes.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
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
                    if (column.foreignKey != null || column.isNullable) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (column.isNullable) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colors.secondary,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: theme.colors.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'nullable',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                            ),
                            if (column.foreignKey != null)
                              const SizedBox(width: 6),
                          ],
                          if (column.foreignKey != null)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
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
                                    Icon(
                                      Icons.link,
                                      size: 10,
                                      color: theme.colors.foreground,
                                    ),
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
                            ),
                        ],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: idx.isPrimaryKey
                            ? Colors.amber.withValues(alpha: 0.2)
                            : theme.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: idx.isPrimaryKey
                              ? Colors.amber.shade700
                              : theme.colors.primary,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        idx.isPrimaryKey ? 'PK' : 'UNIQUE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: idx.isPrimaryKey
                              ? Colors.amber.shade700
                              : theme.colors.primary,
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

class _ForeignRowPreviewPanel extends StatelessWidget {
  final TableTabKey tableKey;
  final TableDataSession session;

  const _ForeignRowPreviewPanel({
    required this.tableKey,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final preview = session.foreignRowPreview!;

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
                  Icons.open_in_new,
                  size: 14,
                  color: theme.colors.foreground,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    preview.tableName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close preview',
                  padding: EdgeInsets.zero,
                  splashRadius: 12,
                  onPressed: () => context
                      .read<TableDataCubit>()
                      .clearForeignRowPreview(tableKey),
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
              itemCount: preview.structure.columns.length,
              itemBuilder: (context, index) => _RowDetailField(
                column: preview.structure.columns[index],
                value: preview.row.cells[index],
              ),
            ),
          ),
        ],
      ),
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
                const SizedBox(height: 8),
                _InspectorMetric(
                  label: 'New rows inserted',
                  value: session.stagedInsertedRowIndexes.length.toString(),
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
    final inserts = session.stagedInsertedRowIndexes.length;
    if (edits == 0 && deletes == 0 && inserts == 0) {
      return 'Use Ctrl/Cmd-click to toggle rows and Shift-click to select a range on this page.';
    }
    return '${session.selectionCount} rows selected, '
        '$edits staged cell edits, $deletes rows marked for delete, $inserts new rows inserted.';
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
  final _pinnedVertical = ScrollController();
  final _scrollVertical = ScrollController();
  final _focusNode = FocusNode(debugLabel: 'table-data-grid');
  bool _syncingVerticalScroll = false;

  @override
  void initState() {
    super.initState();
    _pinnedVertical.addListener(
      () => _syncVerticalScroll(_pinnedVertical, _scrollVertical),
    );
    _scrollVertical.addListener(
      () => _syncVerticalScroll(_scrollVertical, _pinnedVertical),
    );
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _pinnedVertical.dispose();
    _scrollVertical.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncVerticalScroll(ScrollController source, ScrollController target) {
    if (_syncingVerticalScroll || !source.hasClients || !target.hasClients) {
      return;
    }
    final targetPosition = source.offset.clamp(
      target.position.minScrollExtent,
      target.position.maxScrollExtent,
    );
    if ((target.offset - targetPosition).abs() < 0.5) return;

    _syncingVerticalScroll = true;
    target.jumpTo(targetPosition);
    _syncingVerticalScroll = false;
  }

  void _moveSelection(int delta) {
    final idx =
        widget.session.singleSelectedRowIndex ??
        widget.session.selectionAnchorRowIndex;
    if (idx != null) {
      final nextIdx = (idx + delta).clamp(0, widget.session.rows.length - 1);
      context.read<TableDataCubit>().selectSingleRow(widget.tableKey, nextIdx);
    } else if (widget.session.rows.isNotEmpty) {
      context.read<TableDataCubit>().selectSingleRow(widget.tableKey, 0);
    }
  }

  Future<void> _copySelectedRows() async {
    if (widget.session.selectedRowIndexes.isEmpty) return;

    final rowIndex = widget.session.selectedRowIndexes.reduce(
      (a, b) => a < b ? a : b,
    );
    await _copyRows(rowIndex);
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.session.structure!.columns;
    final widths = columns.map(_columnWidth).toList();
    final pinnedColumnIndexes = [
      for (var index = 0; index < columns.length; index++)
        if (widget.session.pinnedColumnIndexes.contains(index)) index,
    ];
    final hasPinnedColumns = pinnedColumnIndexes.isNotEmpty;
    final scrollColumnIndexes = [
      for (var index = 0; index < columns.length; index++)
        if (!widget.session.pinnedColumnIndexes.contains(index)) index,
    ];
    final pinnedWidth = pinnedColumnIndexes.fold<double>(
      0,
      (sum, index) => sum + widths[index],
    );
    final scrollWidth = scrollColumnIndexes.fold<double>(
      0,
      (sum, index) => sum + widths[index],
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveSelection(-1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveSelection(1),
        KeyboardShortcuts.copy: _copySelectedRows,
        const SingleActivator(LogicalKeyboardKey.enter): () {
          final idx = widget.session.singleSelectedRowIndex;
          if (idx != null) {
            context.read<TableDataCubit>().beginCellEdit(
              widget.tableKey,
              idx,
              0,
            );
          }
        },
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableScrollWidth = (constraints.maxWidth - pinnedWidth)
                .clamp(0.0, double.infinity);
            final contentWidth = scrollWidth < availableScrollWidth
                ? availableScrollWidth
                : scrollWidth;

            return Row(
              children: [
                if (hasPinnedColumns)
                  SizedBox(
                    width: pinnedWidth,
                    height: constraints.maxHeight,
                    child: _GridColumnGroup(
                      tableKey: widget.tableKey,
                      session: widget.session,
                      columns: columns,
                      widths: widths,
                      columnIndexes: pinnedColumnIndexes,
                      verticalController: _pinnedVertical,
                      onRequestKeyboardFocus: _focusNode.requestFocus,
                      onCopyRows: _copyRows,
                      onOpenForeignKey: _openForeignKey,
                    ),
                  ),
                Expanded(
                  child: Scrollbar(
                    controller: _horizontal,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _horizontal,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: contentWidth,
                        height: constraints.maxHeight,
                        child: _GridColumnGroup(
                          tableKey: widget.tableKey,
                          session: widget.session,
                          columns: columns,
                          widths: widths,
                          columnIndexes: scrollColumnIndexes,
                          verticalController: hasPinnedColumns
                              ? _scrollVertical
                              : null,
                          onRequestKeyboardFocus: _focusNode.requestFocus,
                          onCopyRows: _copyRows,
                          onOpenForeignKey: _openForeignKey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openForeignKey(TableForeignKey fk, TableCellValue value) {
    context.read<TableDataCubit>().previewForeignRow(
      widget.tableKey,
      fk,
      value.rawValue?.toString() ?? value.display,
    );
  }

  double _columnWidth(TableDataColumn column) {
    final nameWidth = column.name.length * 8.0 + 36;
    final dataWidth = column.length.clamp(8, 28) * 7.0 + 24;
    return (nameWidth > dataWidth ? nameWidth : dataWidth).clamp(120, 280);
  }

  Future<void> _copyRows(int rowIndex, [_CopyRowsFormat? format]) async {
    final text = switch (format) {
      _CopyRowsFormat.csv => formatCopiedTableRowsAsCsv(
        widget.session,
        rowIndex,
      ),
      _CopyRowsFormat.sql => formatCopiedTableRowsAsSql(
        widget.session,
        rowIndex,
        tableName: widget.tableKey.tableName,
      ),
      _CopyRowsFormat.json => formatCopiedTableRowsAsJson(
        widget.session,
        rowIndex,
      ),
      null => formatCopiedTableRows(widget.session, rowIndex),
    };
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showFToast(
      context: context,
      variant: FToastVariant.primary,
      title: const Text('Copied to clipboard'),
    );
  }
}

enum _CopyRowsFormat { csv, sql, json }

String formatCopiedTableRows(TableDataSession session, int rowIndex) {
  final rowLines = _copyTargetRows(session, rowIndex)
      .where((index) => index >= 0 && index < session.rows.length)
      .map((index) {
        final row = session.rows[index];
        return [
          for (
            var columnIndex = 0;
            columnIndex < row.cells.length;
            columnIndex++
          )
            _quotedCopyCell(
              session
                      .stagedCellEdits[TableCellCoordinate(
                        rowIndex: index,
                        columnIndex: columnIndex,
                      )]
                      ?.draftText ??
                  row.cells[columnIndex].display,
            ),
        ].join(' ');
      })
      .toList();
  final header = session.structure?.columns
      .map((column) => _quotedCopyCell(column.name))
      .join(' ');
  return [
    if (header != null && header.isNotEmpty) header,
    ...rowLines,
  ].join('\n');
}

String formatCopiedTableRowsAsCsv(TableDataSession session, int rowIndex) {
  final columns = session.structure?.columns ?? const <TableDataColumn>[];
  final lines = <String>[
    if (columns.isNotEmpty)
      columns.map((column) => _csvCell(column.name)).join(','),
    for (final index in _copyTargetRows(session, rowIndex))
      if (index >= 0 && index < session.rows.length)
        [
          for (
            var columnIndex = 0;
            columnIndex < session.rows[index].cells.length;
            columnIndex++
          )
            _csvCell(_copyCellText(session, index, columnIndex)),
        ].join(','),
  ];
  return lines.join('\n');
}

String formatCopiedTableRowsAsSql(
  TableDataSession session,
  int rowIndex, {
  required String tableName,
}) {
  final columns = session.structure?.columns ?? const <TableDataColumn>[];
  final rows = _copyTargetRows(
    session,
    rowIndex,
  ).where((index) => index >= 0 && index < session.rows.length).toList();
  if (columns.isEmpty || rows.isEmpty) return '';

  final identifiers = columns
      .map((column) => _sqlIdentifier(column.name))
      .join(', ');
  final values = rows
      .map((rowIndex) {
        final row = session.rows[rowIndex];
        return '(${[for (var columnIndex = 0; columnIndex < row.cells.length; columnIndex++) _sqlValue(session, rowIndex, columnIndex)].join(', ')})';
      })
      .join(',\n');
  return 'INSERT INTO ${_sqlIdentifier(tableName)} ($identifiers) VALUES\n$values;';
}

String formatCopiedTableRowsAsJson(TableDataSession session, int rowIndex) {
  final columns = session.structure?.columns ?? const <TableDataColumn>[];
  final rows = [
    for (final rowIndex in _copyTargetRows(session, rowIndex))
      if (rowIndex >= 0 && rowIndex < session.rows.length)
        {
          for (
            var columnIndex = 0;
            columnIndex < columns.length &&
                columnIndex < session.rows[rowIndex].cells.length;
            columnIndex++
          )
            columns[columnIndex].name: _jsonValue(
              session,
              rowIndex,
              columnIndex,
            ),
        },
  ];
  return const JsonEncoder.withIndent('  ').convert(rows);
}

List<int> _copyTargetRows(TableDataSession session, int rowIndex) {
  return session.selectedRowIndexes.contains(rowIndex)
      ? (session.selectedRowIndexes.toList()..sort())
      : [rowIndex];
}

String _copyCellText(TableDataSession session, int rowIndex, int columnIndex) {
  return session
          .stagedCellEdits[TableCellCoordinate(
            rowIndex: rowIndex,
            columnIndex: columnIndex,
          )]
          ?.draftText ??
      session.rows[rowIndex].cells[columnIndex].display;
}

bool _copyCellIsNull(TableDataSession session, int rowIndex, int columnIndex) {
  return !session.stagedCellEdits.containsKey(
        TableCellCoordinate(rowIndex: rowIndex, columnIndex: columnIndex),
      ) &&
      session.rows[rowIndex].cells[columnIndex].kind == TableCellKind.nullValue;
}

String _quotedCopyCell(String value) {
  final trimmed = value.trimLeft();
  final looksLikeJson =
      (trimmed.startsWith('{') && value.trimRight().endsWith('}')) ||
      (trimmed.startsWith('[') && value.trimRight().endsWith(']'));
  final hasWhitespace = RegExp(r'\s').hasMatch(value);
  if (!looksLikeJson && !hasWhitespace) return value;

  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

String _csvCell(String value) {
  final mustQuote =
      value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      RegExp(r'\s').hasMatch(value) ||
      _looksLikeJson(value);
  if (!mustQuote) return value;
  return '"${value.replaceAll('"', '""')}"';
}

String _sqlIdentifier(String value) => '"${value.replaceAll('"', '""')}"';

String _sqlValue(TableDataSession session, int rowIndex, int columnIndex) {
  if (_copyCellIsNull(session, rowIndex, columnIndex)) return 'NULL';
  return "'${_copyCellText(session, rowIndex, columnIndex).replaceAll("'", "''")}'";
}

Object? _jsonValue(TableDataSession session, int rowIndex, int columnIndex) {
  if (_copyCellIsNull(session, rowIndex, columnIndex)) return null;
  return _structuredJsonValue(_copyCellText(session, rowIndex, columnIndex));
}

Object? _structuredJsonValue(String value) {
  if (!_looksLikeJson(value)) return value;

  final trimmed = value.trim();
  try {
    return jsonDecode(trimmed);
  } on FormatException {
    final looseMap = _parseLooseMap(trimmed);
    return looseMap ?? value;
  }
}

Map<String, String>? _parseLooseMap(String value) {
  if (!value.startsWith('{') || !value.endsWith('}')) return null;

  final body = value.substring(1, value.length - 1).trim();
  if (body.isEmpty) return <String, String>{};

  final entries = <String, String>{};
  for (final part in body.split(',')) {
    final separator = part.indexOf(':');
    if (separator <= 0) return null;

    final key = part.substring(0, separator).trim();
    final parsedValue = part.substring(separator + 1).trim();
    if (key.isEmpty) return null;

    entries[key] = parsedValue;
  }
  return entries;
}

bool _looksLikeJson(String value) {
  final trimmed = value.trimLeft();
  return (trimmed.startsWith('{') && value.trimRight().endsWith('}')) ||
      (trimmed.startsWith('[') && value.trimRight().endsWith(']'));
}

class _GridColumnGroup extends StatelessWidget {
  final TableTabKey tableKey;
  final TableDataSession session;
  final List<TableDataColumn> columns;
  final List<double> widths;
  final List<int> columnIndexes;
  final ScrollController? verticalController;
  final VoidCallback onRequestKeyboardFocus;
  final Future<void> Function(int rowIndex, [_CopyRowsFormat? format])
  onCopyRows;
  final void Function(TableForeignKey, TableCellValue)? onOpenForeignKey;

  const _GridColumnGroup({
    required this.tableKey,
    required this.session,
    required this.columns,
    required this.widths,
    required this.columnIndexes,
    required this.verticalController,
    required this.onRequestKeyboardFocus,
    required this.onCopyRows,
    this.onOpenForeignKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeaderRow(
          tableKey: tableKey,
          columns: columns,
          widths: widths,
          columnIndexes: columnIndexes,
          pinnedColumnIndexes: session.pinnedColumnIndexes,
        ),
        Expanded(
          child: session.rows.isEmpty
              ? const _NoRows()
              : ListView.builder(
                  controller: verticalController,
                  itemExtent: 34,
                  itemCount: session.rows.length,
                  itemBuilder: (context, index) => _GridRow(
                    tableKey: tableKey,
                    rowIndex: index,
                    row: session.rows[index],
                    widths: widths,
                    columnIndexes: columnIndexes,
                    selected: session.selectedRowIndexes.contains(index),
                    activeEdit: session.activeCellEdit,
                    stagedEdits: session.stagedCellEdits,
                    stagedDelete: session.stagedDeletedRowIndexes.contains(
                      index,
                    ),
                    stagedInsert: session.stagedInsertedRowIndexes.contains(
                      index,
                    ),
                    editable: session.isEditable,
                    columns: columns,
                    onRequestKeyboardFocus: onRequestKeyboardFocus,
                    onCopyRows: (format) => onCopyRows(index, format),
                    onOpenForeignKey: onOpenForeignKey,
                  ),
                ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final TableTabKey tableKey;
  final List<TableDataColumn> columns;
  final List<double> widths;
  final List<int> columnIndexes;
  final Set<int> pinnedColumnIndexes;

  const _HeaderRow({
    required this.tableKey,
    required this.columns,
    required this.widths,
    required this.columnIndexes,
    required this.pinnedColumnIndexes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      height: 34,
      color: theme.colors.secondary,
      child: Row(
        children: [
          for (final index in columnIndexes)
            _HeaderCell(
              tableKey: tableKey,
              column: columns[index],
              columnIndex: index,
              width: widths[index],
              pinned: pinnedColumnIndexes.contains(index),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final TableTabKey tableKey;
  final TableDataColumn column;
  final int columnIndex;
  final double width;
  final bool pinned;

  const _HeaderCell({
    required this.tableKey,
    required this.column,
    required this.columnIndex,
    required this.width,
    required this.pinned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FContextMenu(
      menuBuilder: (context, controller, menu) => [
        FItemGroup(
          children: [
            FItem(
              prefix: Icon(
                pinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 14,
              ),
              title: Text(pinned ? 'Unpin column' : 'Pin column'),
              onPress: () {
                controller.hide();
                if (pinned) {
                  context.read<TableDataCubit>().unpinColumn(
                    tableKey,
                    columnIndex,
                  );
                } else {
                  context.read<TableDataCubit>().pinColumn(
                    tableKey,
                    columnIndex,
                  );
                }
              },
            ),
          ],
        ),
      ],
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: pinned ? theme.colors.primary.withValues(alpha: 0.08) : null,
          border: Border(
            right: BorderSide(
              color: pinned ? theme.colors.primary : theme.colors.border,
              width: pinned ? 1.5 : 1,
            ),
            bottom: BorderSide(color: theme.colors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (pinned) ...[
              Icon(Icons.push_pin, size: 12, color: theme.colors.primary),
              const SizedBox(width: 5),
            ],
            if (column.isPrimaryKey) ...[
              Icon(
                Icons.key_outlined,
                size: 12,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(width: 5),
            ],
            if (column.foreignKey != null) ...[
              Icon(Icons.link, size: 12, color: theme.colors.mutedForeground),
              const SizedBox(width: 5),
            ],
            Expanded(
              child: Text(
                column.name,
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
    );
  }
}

class _GridRow extends StatelessWidget {
  final TableTabKey tableKey;
  final int rowIndex;
  final TableDataRow row;
  final List<double> widths;
  final List<int> columnIndexes;
  final bool selected;
  final TableCellEdit? activeEdit;
  final Map<TableCellCoordinate, TableCellEdit> stagedEdits;
  final bool stagedDelete;
  final bool stagedInsert;
  final bool editable;
  final List<TableDataColumn> columns;
  final VoidCallback onRequestKeyboardFocus;
  final void Function(_CopyRowsFormat? format) onCopyRows;
  final void Function(TableForeignKey, TableCellValue)? onOpenForeignKey;

  const _GridRow({
    required this.tableKey,
    required this.rowIndex,
    required this.row,
    required this.widths,
    required this.columnIndexes,
    required this.selected,
    required this.activeEdit,
    required this.stagedEdits,
    required this.stagedDelete,
    required this.stagedInsert,
    required this.editable,
    required this.columns,
    required this.onRequestKeyboardFocus,
    required this.onCopyRows,
    this.onOpenForeignKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FContextMenu(
      menuBuilder: (context, controller, menu) => [
        FItemGroup(
          children: [
            FItem(
              prefix: const Icon(Icons.copy_outlined, size: 14),
              title: const Text('Copy'),
              onPress: () {
                controller.hide();
                onCopyRows(null);
              },
            ),
            FSubmenuItem(
              prefix: const Icon(Icons.file_copy_outlined, size: 14),
              title: const Text('Copy as'),
              submenu: [
                FItemGroup(
                  children: [
                    FItem(
                      title: const Text('CSV'),
                      onPress: () {
                        controller.hide();
                        onCopyRows(_CopyRowsFormat.csv);
                      },
                    ),
                    FItem(
                      title: const Text('SQL'),
                      onPress: () {
                        controller.hide();
                        onCopyRows(_CopyRowsFormat.sql);
                      },
                    ),
                    FItem(
                      title: const Text('JSON'),
                      onPress: () {
                        controller.hide();
                        onCopyRows(_CopyRowsFormat.json);
                      },
                    ),
                  ],
                ),
              ],
            ),
            FItem(
              enabled: editable,
              prefix: const Icon(Icons.control_point_duplicate, size: 14),
              title: const Text('Duplicate'),
              onPress: editable
                  ? () {
                      controller.hide();
                      context.read<TableDataCubit>().stageDuplicateForRow(
                        tableKey,
                        rowIndex,
                      );
                    }
                  : null,
            ),
            FItem(
              variant: FItemVariant.destructive,
              enabled: editable,
              prefix: const Icon(Icons.delete_outline, size: 14),
              title: const Text('Delete'),
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
            : stagedInsert
            ? Colors.green.withValues(alpha: 0.18)
            : selected
            ? theme.colors.secondary
            : Colors.transparent,
        child: Row(
          children: [
            for (final index in columnIndexes)
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
                inserted: stagedInsert,
                onActivate: () {
                  onRequestKeyboardFocus();
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
                onNavigate: (reverse) {
                  final session = context.read<TableDataCubit>().state.session(
                    tableKey,
                  );
                  if (session == null) return;
                  final nextCol = reverse
                      ? activeEdit!.columnIndex - 1
                      : activeEdit!.columnIndex + 1;
                  if (nextCol >= 0 &&
                      nextCol < session.structure!.columns.length) {
                    context.read<TableDataCubit>().beginCellEdit(
                      tableKey,
                      activeEdit!.rowIndex,
                      nextCol,
                    );
                  } else if (nextCol >= session.structure!.columns.length) {
                    // wrap to next row
                    final nextRow = activeEdit!.rowIndex + 1;
                    if (nextRow < session.rows.length) {
                      context.read<TableDataCubit>().beginCellEdit(
                        tableKey,
                        nextRow,
                        0,
                      );
                    }
                  } else if (nextCol < 0) {
                    // wrap to prev row
                    final prevRow = activeEdit!.rowIndex - 1;
                    if (prevRow >= 0) {
                      context.read<TableDataCubit>().beginCellEdit(
                        tableKey,
                        prevRow,
                        session.structure!.columns.length - 1,
                      );
                    }
                  }
                },
                onNavigateRow: (reverse) {
                  final session = context.read<TableDataCubit>().state.session(
                    tableKey,
                  );
                  if (session == null) return;
                  final nextRow = reverse
                      ? activeEdit!.rowIndex - 1
                      : activeEdit!.rowIndex + 1;
                  if (nextRow >= 0 && nextRow < session.rows.length) {
                    context.read<TableDataCubit>().beginCellEdit(
                      tableKey,
                      nextRow,
                      activeEdit!.columnIndex,
                    );
                  }
                },
                foreignKey: columns[index].foreignKey,
                onOpenForeignKey:
                    columns[index].foreignKey != null &&
                        onOpenForeignKey != null
                    ? () => onOpenForeignKey!(
                        columns[index].foreignKey!,
                        row.cells[index],
                      )
                    : null,
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
  final bool inserted;
  final VoidCallback onActivate;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool>? onNavigate;
  final ValueChanged<bool>? onNavigateRow;
  final TableForeignKey? foreignKey;
  final VoidCallback? onOpenForeignKey;

  const _GridCell({
    required this.rowIndex,
    required this.columnIndex,
    required this.value,
    required this.width,
    required this.activeEdit,
    required this.stagedEdit,
    required this.deleted,
    required this.inserted,
    required this.onActivate,
    required this.onChanged,
    this.onNavigate,
    this.onNavigateRow,
    this.foreignKey,
    this.onOpenForeignKey,
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

    Widget content = fullText != null && fullText.length > 24
        ? FTooltip(
            tipBuilder: (context, controller) => ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(fullText),
            ),
            child: text,
          )
        : text;

    if (activeEdit == null &&
        foreignKey != null &&
        value.kind != TableCellKind.nullValue &&
        onOpenForeignKey != null) {
      content = Row(
        children: [
          Expanded(child: content),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenForeignKey,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Icon(
                  Icons.open_in_new,
                  size: 12,
                  color: theme.colors.primary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: activeEdit == null ? onActivate : null,
      child: Container(
        width: width,
        height: 34,
        padding: activeEdit == null
            ? const EdgeInsets.symmetric(horizontal: 10)
            : EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: pendingEdit && !deleted && !inserted
              ? Colors.amber.withValues(alpha: 0.16)
              : null,
          border: Border(
            right: BorderSide(
              color: inserted ? Colors.green : theme.colors.border,
              width: 1,
            ),
            bottom: BorderSide(
              color: inserted ? Colors.green : theme.colors.border,
              width: inserted ? 1 : 0.5,
            ),
          ),
        ),
        child: activeEdit != null
            ? _CellTextField(
                edit: activeEdit!,
                onChanged: onChanged,
                onNavigate: onNavigate,
                onNavigateRow: onNavigateRow,
              )
            : content,
      ),
    );
  }
}

class _CellTextField extends StatefulWidget {
  final TableCellEdit edit;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool>? onNavigate;
  final ValueChanged<bool>? onNavigateRow;

  const _CellTextField({
    required this.edit,
    required this.onChanged,
    this.onNavigate,
    this.onNavigateRow,
  });

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
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            final shift = HardwareKeyboard.instance.isShiftPressed;
            widget.onNavigate?.call(shift);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            widget.onNavigateRow?.call(false);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
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
                    FTooltip(
                      tipBuilder: (context, controller) => Text(
                        'Commit changes (${KeyboardShortcuts.format('Cmd-S')})',
                      ),
                      child: FButton(
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
                          session.isCommittingChanges
                              ? 'Committing…'
                              : 'Commit',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    FTooltip(
                      tipBuilder: (context, controller) =>
                          const Text('Cancel changes (Esc)'),
                      child: FButton(
                        size: FButtonSizeVariant.xs,
                        variant: FButtonVariant.outline,
                        onPress: session.isCommittingChanges
                            ? null
                            : () => context
                                  .read<TableDataCubit>()
                                  .clearPendingChanges(tableKey),
                        child: const Text('Cancel'),
                      ),
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
                        const Text('Insert Row'),
                    child: FButton.icon(
                      size: FButtonSizeVariant.xs,
                      variant: FButtonVariant.outline,
                      onPress: disabled
                          ? null
                          : () => context.read<TableDataCubit>().stageInsert(
                              tableKey,
                            ),
                      child: const Icon(Icons.add, size: 14),
                    ),
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
  late String _lastSessionSearchQuery;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _lastSessionSearchQuery = widget.session.searchQuery ?? '';
    _searchController = TextEditingController(text: _lastSessionSearchQuery);
  }

  @override
  void didUpdateWidget(covariant _TableActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sessionSearchQuery = widget.session.searchQuery ?? '';
    if (sessionSearchQuery == _lastSessionSearchQuery) return;

    _lastSessionSearchQuery = sessionSearchQuery;
    if (_debounce?.isActive ?? false) return;

    if (sessionSearchQuery != _searchController.text) {
      _searchController.value = TextEditingValue(
        text: sessionSearchQuery,
        selection: TextSelection.collapsed(offset: sessionSearchQuery.length),
      );
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
      final selectedColumn =
          widget.session.searchColumn ??
          widget.session.structure?.columns.firstOrNull?.name ??
          '__ALL__';
      context.read<TableDataCubit>().setSearch(
        widget.tableKey,
        query: query,
        column: selectedColumn,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: _searchController,
                onChange: (value) => _onSearchChanged(value.text),
              ),
              hint: 'Search...',
              maxLines: 1,
              size: FTextFieldSizeVariant.sm,
              clearable: (value) => value.text.isNotEmpty,
              suffixBuilder: (context, fieldStyle, widgetWidget) {
                final columns = widget.session.structure?.columns ?? [];
                if (columns.isEmpty) return const SizedBox.shrink();

                final items = {
                  '__ALL__': 'All',
                  for (final col in columns) col.name: col.name,
                };

                final selectedValue =
                    widget.session.searchColumn ??
                    columns.firstOrNull?.name ??
                    '__ALL__';

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FPopoverMenu(
                    menuBuilder: (context, controller, menu) => [
                      FItemGroup(
                        children: [
                          for (final entry in items.entries)
                            FItem(
                              title: Text(entry.value),
                              onPress: () {
                                controller.hide();
                                context.read<TableDataCubit>().setSearch(
                                  widget.tableKey,
                                  column: entry.key,
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                    builder: (context, controller, child) {
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: controller.toggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                                Text(
                                  items[selectedValue] ?? 'All',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 14,
                                  color: theme.colors.mutedForeground,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
    _rows = widget.initialFilters
        .map(
          (f) => _FilterFormRow(
            column: f.column,
            operator: f.operator,
            valueController: TextEditingController(text: f.value),
          ),
        )
        .toList();

    if (_rows.isEmpty) {
      _rows.add(
        _FilterFormRow(
          column: widget.columns.isNotEmpty ? widget.columns.first.name : '',
          operator: widget.operators.isNotEmpty ? widget.operators.first : '=',
          valueController: TextEditingController(),
        ),
      );
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
      _rows.add(
        _FilterFormRow(
          column: widget.columns.isNotEmpty ? widget.columns.first.name : '',
          operator: widget.operators.isNotEmpty ? widget.operators.first : '=',
          valueController: TextEditingController(),
        ),
      );
    });
  }

  void _removeFilter(int index) {
    setState(() {
      final removed = _rows.removeAt(index);
      removed.valueController.dispose();
    });
  }

  void _applyFilters() {
    final filters = _rows
        .where((row) => row.column.isNotEmpty && row.operator.isNotEmpty)
        .map(
          (row) => TableFilter(
            column: row.column,
            operator: row.operator,
            value: row.valueController.text,
          ),
        )
        .toList();
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
              border: Border(
                bottom: BorderSide(color: theme.colors.border, width: 1),
              ),
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
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: theme.colors.mutedForeground,
                  ),
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
                        items: {for (var c in widget.columns) c.name: c.name},
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
                        items: {for (var op in widget.operators) op: op},
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
              border: Border(
                top: BorderSide(color: theme.colors.border, width: 1),
              ),
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
                FButton(onPress: _applyFilters, child: const Text('Filter')),
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
