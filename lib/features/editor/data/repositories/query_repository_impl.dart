import 'package:sqflite_common/sqlite_api.dart';

import '../../domain/entities/connection_query.dart';
import '../../domain/repositories/query_repository.dart';

class QueryRepositoryImpl implements QueryRepository {
  static const tableName = 'queries';

  final Database _database;

  // ignore: prefer_initializing_formals
  QueryRepositoryImpl({required Database database}) : _database = database;

  @override
  Future<List<ConnectionQuery>> getAllForConnection(String connectionId) async {
    final rows = await _database.query(
      tableName,
      where: 'connection_id = ?',
      whereArgs: [connectionId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<ConnectionQuery> save(ConnectionQuery query) async {
    await _database.insert(tableName, {
      'id': query.id,
      'connection_id': query.connectionId,
      'title': query.title,
      'sql': query.sql,
      'database': query.database,
      'created_at': query.createdAt.millisecondsSinceEpoch,
      'updated_at': query.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return query;
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteByConnection(String connectionId) async {
    await _database.delete(
      tableName,
      where: 'connection_id = ?',
      whereArgs: [connectionId],
    );
  }

  ConnectionQuery _fromRow(Map<String, Object?> row) {
    return ConnectionQuery(
      id: row['id']! as String,
      connectionId: row['connection_id']! as String,
      title: row['title']! as String,
      sql: row['sql']! as String,
      database: row['database'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
    );
  }
}
