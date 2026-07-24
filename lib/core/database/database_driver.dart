import '../../../features/connections/domain/entities/connection.dart';
import '../../../features/editor/domain/entities/query_history.dart';
import '../../../features/editor/domain/entities/query_result.dart';
import '../../../features/editor/domain/entities/table_data.dart';
import '../../../features/editor/domain/entities/connection_database.dart';
import '../../../features/editor/domain/entities/connection_schema.dart';
import '../../../features/editor/domain/entities/connection_table.dart';

abstract class DatabaseDriver {
  List<String> get supportedOperators;

  Future<void> testConnection(Connection connection);

  Future<List<ConnectionDatabase>> listDatabases(Connection connection);

  Future<List<ConnectionSchema>> listSchemas(
    Connection connection,
    String database,
  );

  Future<List<ConnectionTable>> listTables(
    Connection connection,
    String database,
    String? schema,
  );

  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table, {
    String? schema,
    void Function(QueryHistory)? onHistory,
  });

  Future<int> countRows(
    Connection connection,
    String database,
    String table, {
    String? schema,
    required TableStructure structure,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
    void Function(QueryHistory)? onHistory,
  });

  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    String? schema,
    required TableStructure structure,
    required int offset,
    required int limit,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
    void Function(QueryHistory)? onHistory,
  });

  Future<void> commitChanges(
    Connection connection,
    String database,
    String table, {
    String? schema,
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
    String? schema,
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
    String? schema,
    String tableName,
    List<TableColumnDefinition> columns,
  );

  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String? schema,
    String table,
  );

  Future<void> createSchema(
    Connection connection,
    String database,
    String name,
  );

  Future<void> alterTable(
    Connection connection,
    String database,
    String? schema,
    String oldTableName,
    String newTableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  );

  Future<void> dropTable(
    Connection connection,
    String database,
    String table, {
    String? schema,
    bool cascade = false,
  });

  Future<void> truncateTable(
    Connection connection,
    String database,
    String table, {
    String? schema,
    bool cascade = false,
  });
}
