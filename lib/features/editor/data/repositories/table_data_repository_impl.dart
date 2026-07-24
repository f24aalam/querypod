import '../../../../core/database/database_driver_factory.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/query_result.dart';
import '../../domain/entities/table_data.dart';
import '../../domain/repositories/query_history_repository.dart';
import '../../domain/repositories/table_data_repository.dart';

class TableDataRepositoryImpl implements TableDataRepository {
  final QueryHistoryRepository _historyRepository;

  TableDataRepositoryImpl({required QueryHistoryRepository historyRepository})
    // ignore: prefer_initializing_formals
    : _historyRepository = historyRepository;

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
    String? schema,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.inspectTable(
      connection,
      database,
      table,
      schema: schema,
      onHistory: _historyRepository.save,
    );
  }

  @override
  Future<int> countRows(
    Connection connection,
    String database,
    String table, {
    String? schema,
    required TableStructure structure,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
  }) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.countRows(
      connection,
      database,
      table,
      schema: schema,
      structure: structure,
      searchQuery: searchQuery,
      searchColumn: searchColumn,
      filters: filters,
      onHistory: _historyRepository.save,
    );
  }

  @override
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
  }) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.fetchRows(
      connection,
      database,
      table,
      schema: schema,
      structure: structure,
      offset: offset,
      limit: limit,
      searchQuery: searchQuery,
      searchColumn: searchColumn,
      filters: filters,
      onHistory: _historyRepository.save,
    );
  }

  @override
  Future<void> commitChanges(
    Connection connection,
    String database,
    String table, {
    String? schema,
    required TableStructure structure,
    required List<TableCellChange> cellChanges,
    required List<TableDataRow> deletedRows,
    required List<Map<String, dynamic>> insertedRows,
  }) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.commitChanges(
      connection,
      database,
      table,
      schema: schema,
      structure: structure,
      cellChanges: cellChanges,
      deletedRows: deletedRows,
      insertedRows: insertedRows,
      onHistory: _historyRepository.save,
    );
  }

  @override
  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
    String? schema,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.executeQuery(connection, database, sql, schema);
  }
}
