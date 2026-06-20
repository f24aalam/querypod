import '../../domain/entities/table_data.dart';
import 'editor_tabs_state.dart';

enum TableDataStatus { initialLoading, ready, pageLoading, refreshing, error }

class TableDataSession {
  final TableTabKey key;
  final TableStructure? structure;
  final List<TableDataRow> rows;
  final int totalCount;
  final int pageIndex;
  final int pageSize;
  final Set<int> selectedRowIndexes;
  final int? selectionAnchorRowIndex;
  final TableCellEdit? activeCellEdit;
  final Map<TableCellCoordinate, TableCellEdit> stagedCellEdits;
  final Set<int> stagedDeletedRowIndexes;
  final bool isCommittingChanges;
  final Duration queryDuration;
  final TableDataStatus status;
  final String? errorMessage;
  final int feedbackNonce;

  TableDataSession({
    required this.key,
    this.structure,
    List<TableDataRow> rows = const [],
    this.totalCount = 0,
    this.pageIndex = 0,
    this.pageSize = 50,
    Set<int> selectedRowIndexes = const {},
    this.selectionAnchorRowIndex,
    this.activeCellEdit,
    Map<TableCellCoordinate, TableCellEdit> stagedCellEdits = const {},
    Set<int> stagedDeletedRowIndexes = const {},
    this.isCommittingChanges = false,
    this.queryDuration = Duration.zero,
    this.status = TableDataStatus.initialLoading,
    this.errorMessage,
    this.feedbackNonce = 0,
  }) : rows = List.unmodifiable(rows),
       selectedRowIndexes = Set.unmodifiable(selectedRowIndexes),
       stagedCellEdits = Map.unmodifiable(stagedCellEdits),
       stagedDeletedRowIndexes = Set.unmodifiable(stagedDeletedRowIndexes);

  int get pageCount => totalCount == 0 ? 0 : (totalCount / pageSize).ceil();
  int get rangeStart => rows.isEmpty ? 0 : pageIndex * pageSize + 1;
  int get rangeEnd => rows.isEmpty ? 0 : rangeStart + rows.length - 1;
  bool get canGoPrevious =>
      status != TableDataStatus.pageLoading && pageIndex > 0;
  bool get canGoNext =>
      status != TableDataStatus.pageLoading && rangeEnd < totalCount;
  bool get hasRows => rows.isNotEmpty;
  bool get isEditable =>
      structure?.columns.any((column) => column.isPrimaryKey) ?? false;
  bool get hasSelection => selectedRowIndexes.isNotEmpty;
  int get selectionCount => selectedRowIndexes.length;
  int? get singleSelectedRowIndex =>
      selectionCount == 1 ? selectedRowIndexes.first : null;
  bool get hasPendingEdits => stagedCellEdits.isNotEmpty;
  bool get hasPendingDeletes => stagedDeletedRowIndexes.isNotEmpty;
  bool get hasPendingChanges => hasPendingEdits || hasPendingDeletes;

  TableDataSession copyWith({
    TableStructure? Function()? structure,
    List<TableDataRow>? rows,
    int? totalCount,
    int? pageIndex,
    int? pageSize,
    Set<int>? selectedRowIndexes,
    int? Function()? selectionAnchorRowIndex,
    TableCellEdit? Function()? activeCellEdit,
    Map<TableCellCoordinate, TableCellEdit>? stagedCellEdits,
    Set<int>? stagedDeletedRowIndexes,
    bool? isCommittingChanges,
    Duration? queryDuration,
    TableDataStatus? status,
    String? Function()? errorMessage,
    int? feedbackNonce,
  }) {
    return TableDataSession(
      key: key,
      structure: structure != null ? structure() : this.structure,
      rows: rows ?? this.rows,
      totalCount: totalCount ?? this.totalCount,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
      selectedRowIndexes: selectedRowIndexes ?? this.selectedRowIndexes,
      selectionAnchorRowIndex: selectionAnchorRowIndex != null
          ? selectionAnchorRowIndex()
          : this.selectionAnchorRowIndex,
      activeCellEdit: activeCellEdit != null
          ? activeCellEdit()
          : this.activeCellEdit,
      stagedCellEdits: stagedCellEdits ?? this.stagedCellEdits,
      stagedDeletedRowIndexes:
          stagedDeletedRowIndexes ?? this.stagedDeletedRowIndexes,
      isCommittingChanges: isCommittingChanges ?? this.isCommittingChanges,
      queryDuration: queryDuration ?? this.queryDuration,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      feedbackNonce: feedbackNonce ?? this.feedbackNonce,
    );
  }
}

class TableDataState {
  final Map<TableTabKey, TableDataSession> sessions;

  TableDataState({Map<TableTabKey, TableDataSession> sessions = const {}})
    : sessions = Map.unmodifiable(sessions);

  TableDataSession? session(TableTabKey key) => sessions[key];
}
