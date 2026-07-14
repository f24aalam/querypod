// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';

import '../../../../app/database.dart';
import '../../domain/entities/connection_query.dart';
import '../../domain/repositories/query_repository.dart';

class QueryRepositoryImpl implements QueryRepository {
  final QueryPodDatabase _database;

  QueryRepositoryImpl({required QueryPodDatabase database})
    : _database = database;

  @override
  Future<List<ConnectionQuery>> getAllForConnection(String connectionId) async {
    final query = _database.select(_database.savedQueries)
      ..where((row) => row.connectionId.equals(connectionId))
      ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]);
    final rows = await query.get();
    return rows.map(_toEntity).toList(growable: false);
  }

  @override
  Future<ConnectionQuery> save(ConnectionQuery query) async {
    await _database
        .into(_database.savedQueries)
        .insertOnConflictUpdate(
          SavedQueriesCompanion.insert(
            id: query.id,
            connectionId: query.connectionId,
            title: query.title,
            sql: query.sql,
            database: Value(query.database),
            createdAt: query.createdAt,
            updatedAt: query.updatedAt,
          ),
        );
    return query;
  }

  @override
  Future<void> delete(String id) async {
    await (_database.delete(
      _database.savedQueries,
    )..where((row) => row.id.equals(id))).go();
  }

  @override
  Future<void> deleteByConnection(String connectionId) async {
    await (_database.delete(
      _database.savedQueries,
    )..where((row) => row.connectionId.equals(connectionId))).go();
  }

  ConnectionQuery _toEntity(SavedQueryRow row) => ConnectionQuery(
    id: row.id,
    connectionId: row.connectionId,
    title: row.title,
    sql: row.sql,
    database: row.database,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
