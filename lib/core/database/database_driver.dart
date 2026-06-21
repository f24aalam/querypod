import '../../../features/connections/domain/entities/connection.dart';
import '../../../features/workspace/domain/entities/query_history.dart';
import '../../../features/workspace/domain/entities/query_result.dart';
import '../../../features/workspace/domain/entities/table_data.dart';
import '../../../features/workspace/domain/entities/workspace_database.dart';
import '../../../features/workspace/domain/entities/workspace_table.dart';

abstract class DatabaseDriver {
  Future<void> testConnection(Connection connection);

  Future<List<WorkspaceDatabase>> listDatabases(Connection connection);

  Future<List<WorkspaceTable>> listTables(
    Connection connection,
    String database,
  );

  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table, {
    void Function(QueryHistory)? onHistory,
  });

  Future<int> countRows(
    Connection connection,
    String database,
    String table, {
    void Function(QueryHistory)? onHistory,
  });

  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required int offset,
    required int limit,
    void Function(QueryHistory)? onHistory,
  });

  Future<void> commitChanges(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required List<TableCellChange> cellChanges,
    required List<TableDataRow> deletedRows,
    void Function(QueryHistory)? onHistory,
  });

  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
  );
}
