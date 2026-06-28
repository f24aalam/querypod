import '../../../features/connections/domain/entities/connection.dart';
import '../../../features/editor/domain/entities/query_history.dart';
import '../../../features/editor/domain/entities/query_result.dart';
import '../../../features/editor/domain/entities/table_data.dart';
import '../../../features/editor/domain/entities/connection_database.dart';
import '../../../features/editor/domain/entities/connection_table.dart';

abstract class DatabaseDriver {
  List<String> get supportedOperators;

  Future<void> testConnection(Connection connection);

  Future<List<ConnectionDatabase>> listDatabases(Connection connection);

  Future<List<ConnectionTable>> listTables(
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
    required TableStructure structure,
    String? searchQuery,
    List<TableFilter>? filters,
    void Function(QueryHistory)? onHistory,
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
    void Function(QueryHistory)? onHistory,
  });

  Future<void> commitChanges(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required List<TableCellChange> cellChanges,
    required List<TableDataRow> deletedRows,
    required List<Map<String, dynamic>> insertedRows,
    void Function(QueryHistory)? onHistory,
  });

  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
  );

  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  });

  Future<void> createTable(
    Connection connection,
    String database,
    String tableName,
    List<TableColumnDefinition> columns,
  );

  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String table,
  );

  Future<void> alterTable(
    Connection connection,
    String database,
    String oldTableName,
    String newTableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  );

  Future<void> dropTable(
    Connection connection,
    String database,
    String table, {
    bool cascade = false,
  });

  Future<void> truncateTable(
    Connection connection,
    String database,
    String table, {
    bool cascade = false,
  });
}
