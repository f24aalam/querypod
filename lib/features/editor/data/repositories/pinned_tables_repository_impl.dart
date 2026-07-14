// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';

import '../../../../app/database.dart';
import '../../domain/repositories/pinned_tables_repository.dart';

class PinnedTablesRepositoryImpl implements PinnedTablesRepository {
  final QueryPodDatabase _database;

  PinnedTablesRepositoryImpl({required QueryPodDatabase database})
    : _database = database;

  @override
  Future<List<String>> getPinnedTables({
    required String connectionId,
    required String database,
  }) async {
    final query = _database.select(_database.pinnedTables)
      ..where(
        (row) =>
            row.connectionId.equals(connectionId) &
            row.database.equals(database),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]);
    final rows = await query.get();
    return rows.map((row) => row.table).toList(growable: false);
  }

  @override
  Future<void> setPinnedTables({
    required String connectionId,
    required String database,
    required List<String> tableNames,
  }) async {
    await _database.transaction(() async {
      await (_database.delete(_database.pinnedTables)..where(
            (row) =>
                row.connectionId.equals(connectionId) &
                row.database.equals(database),
          ))
          .go();

      if (tableNames.isEmpty) return;
      await _database.batch((batch) {
        batch.insertAll(_database.pinnedTables, [
          for (final (index, tableName) in tableNames.indexed)
            PinnedTablesCompanion.insert(
              connectionId: connectionId,
              database: database,
              table: tableName,
              sortOrder: index,
            ),
        ]);
      });
    });
  }
}
