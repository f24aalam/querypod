import '../../../connections/domain/entities/connection.dart';
import '../entities/query_result.dart';
import '../entities/table_data.dart';

abstract class TableDataRepository {
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
  );

  Future<int> countRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    String? searchQuery,
    List<TableFilter>? filters,
  });

  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required int offset,
    required int limit,
    String? searchQuery,
    List<TableFilter>? filters,
  });

  Future<void> commitChanges(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required List<TableCellChange> cellChanges,
    required List<TableDataRow> deletedRows,
    required List<Map<String, dynamic>> insertedRows,
  });

  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
  );
}
