import '../../../connections/domain/entities/connection.dart';
import '../entities/table_data.dart';

abstract class TableDataRepository {
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
  );

  Future<int> countRows(Connection connection, String database, String table);

  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required int offset,
    required int limit,
  });

  Future<void> updateCell(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required TableDataRow row,
    required int columnIndex,
    required String value,
  });

  Future<void> deleteRow(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required TableDataRow row,
  });
}
