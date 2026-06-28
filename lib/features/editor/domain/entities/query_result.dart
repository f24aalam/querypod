import 'table_data.dart';

class QueryResult {
  final TableStructure? structure;
  final List<TableDataRow> rows;
  final Duration queryDuration;
  final String? errorMessage;

  const QueryResult({
    this.structure,
    this.rows = const [],
    this.queryDuration = Duration.zero,
    this.errorMessage,
  });
}
