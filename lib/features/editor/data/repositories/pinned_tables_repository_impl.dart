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
    String? schema,
  }) async {
    final schemaKey = _schemaKey(schema);
    final query = _database.select(_database.pinnedTables)
      ..where(
        (row) =>
            row.connectionId.equals(connectionId) &
            row.database.equals(database) &
            row.pgSchema.equals(schemaKey),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]);
    final rows = await query.get();
    return rows.map((row) => row.table).toList(growable: false);
  }

  @override
  Future<void> setPinnedTables({
    required String connectionId,
    required String database,
    String? schema,
    required List<String> tableNames,
  }) async {
    final schemaKey = _schemaKey(schema);
    await _database.transaction(() async {
      await (_database.delete(_database.pinnedTables)..where(
            (row) =>
                row.connectionId.equals(connectionId) &
                row.database.equals(database) &
                row.pgSchema.equals(schemaKey),
          ))
          .go();

      if (tableNames.isEmpty) return;
      await _database.batch((batch) {
        batch.insertAll(_database.pinnedTables, [
          for (final (index, tableName) in tableNames.indexed)
            PinnedTablesCompanion.insert(
              connectionId: connectionId,
              database: database,
              pgSchema: Value(schemaKey),
              table: tableName,
              sortOrder: index,
            ),
        ]);
      });
    });
  }

  String _schemaKey(String? schema) =>
      schema == null || schema.trim().isEmpty ? 'public' : schema.trim();
}
