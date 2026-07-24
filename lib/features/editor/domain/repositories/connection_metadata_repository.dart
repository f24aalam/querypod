import '../../../connections/domain/entities/connection.dart';
import '../entities/connection_database.dart';
import '../entities/connection_schema.dart';
import '../entities/connection_table.dart';
import '../entities/table_data.dart';

abstract class ConnectionMetadataRepository {
  Future<List<ConnectionDatabase>> listDatabases(Connection connection);
  Future<List<ConnectionTable>> listTables(
    Connection connection,
    String database,
    String? schema,
  );
  Future<List<ConnectionSchema>> listSchemas(
    Connection connection,
    String database,
  );
  Future<String?> getSelectedSchema({
    required String connectionId,
    required String database,
  });
  Future<void> setSelectedSchema({
    required String connectionId,
    required String database,
    required String? schema,
  });
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
