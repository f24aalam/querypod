import '../../../connections/domain/entities/connection.dart';
import '../entities/connection_database.dart';
import '../entities/connection_table.dart';
import '../entities/table_data.dart';

abstract class ConnectionMetadataRepository {
  Future<List<ConnectionDatabase>> listDatabases(Connection connection);
  Future<List<ConnectionTable>> listTables(
    Connection connection,
    String database,
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
