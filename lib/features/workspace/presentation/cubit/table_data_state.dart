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
  final int? selectedRowIndex;
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
    this.selectedRowIndex,
    this.queryDuration = Duration.zero,
    this.status = TableDataStatus.initialLoading,
    this.errorMessage,
    this.feedbackNonce = 0,
  }) : rows = List.unmodifiable(rows);

  int get pageCount => totalCount == 0 ? 0 : (totalCount / pageSize).ceil();
  int get rangeStart => rows.isEmpty ? 0 : pageIndex * pageSize + 1;
  int get rangeEnd => rows.isEmpty ? 0 : rangeStart + rows.length - 1;
  bool get canGoPrevious =>
      status != TableDataStatus.pageLoading && pageIndex > 0;
  bool get canGoNext =>
      status != TableDataStatus.pageLoading && rangeEnd < totalCount;
  bool get hasRows => rows.isNotEmpty;

  TableDataSession copyWith({
    TableStructure? Function()? structure,
    List<TableDataRow>? rows,
    int? totalCount,
    int? pageIndex,
    int? pageSize,
    int? Function()? selectedRowIndex,
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
      selectedRowIndex: selectedRowIndex != null
          ? selectedRowIndex()
          : this.selectedRowIndex,
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
