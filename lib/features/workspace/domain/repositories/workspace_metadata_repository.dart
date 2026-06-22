import '../../../connections/domain/entities/connection.dart';
import '../entities/workspace_database.dart';
import '../entities/workspace_table.dart';
import '../entities/table_data.dart';

abstract class WorkspaceMetadataRepository {
  Future<List<WorkspaceDatabase>> listDatabases(Connection connection);
  Future<List<WorkspaceTable>> listTables(
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
}
