import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/database.dart';
import 'package:querypod/features/workspace/data/repositories/query_repository_impl.dart';
import 'package:querypod/features/workspace/domain/entities/workspace_query.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'repository scopes queries by connection and cascades deletes',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'querypod_repo_test',
      );
      final factory = databaseFactoryFfi;
      final originalPath = await factory.getDatabasesPath();
      await factory.setDatabasesPath(tempDir.path);

      final database = await openAppDatabase(databaseFactory: factory);
      final repository = QueryRepositoryImpl(database: database);

      final first = _query(id: 'q1', connectionId: 'conn-1', title: 'demo');
      final second = _query(id: 'q2', connectionId: 'conn-2', title: 'other');
      await repository.save(first);
      await repository.save(second);

      final conn1Queries = await repository.getAllForConnection('conn-1');
      expect(conn1Queries.map((query) => query.id), ['q1']);

      await repository.deleteByConnection('conn-1');
      expect(await repository.getAllForConnection('conn-1'), isEmpty);
      expect(await repository.getAllForConnection('conn-2'), hasLength(1));

      await factory.setDatabasesPath(originalPath);
      await tempDir.delete(recursive: true);
    },
  );
}

WorkspaceQuery _query({
  required String id,
  required String connectionId,
  required String title,
}) {
  final now = DateTime(2026, 1, 1);
  return WorkspaceQuery(
    id: id,
    connectionId: connectionId,
    title: title,
    sql: 'SELECT 1;',
    createdAt: now,
    updatedAt: now,
  );
}
