// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';

import '../../../../app/database.dart';
import '../../../connections/data/services/connection_credential_store.dart';
import '../../domain/entities/app_workspace.dart';
import '../../domain/repositories/workspace_repository.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final QueryPodDatabase _database;
  final ConnectionCredentialStore _credentialStore;

  WorkspaceRepositoryImpl({
    required QueryPodDatabase database,
    required ConnectionCredentialStore credentialStore,
  }) : _database = database,
       _credentialStore = credentialStore;

  @override
  Future<List<AppWorkspace>> getWorkspaces() async {
    final query = _database.select(_database.workspaces)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    final rows = await query.get();
    return rows.map(_toEntity).toList(growable: false);
  }

  @override
  Future<AppWorkspace> getWorkspace(String id) async {
    final query = _database.select(_database.workspaces)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) throw Exception('Workspace not found');
    return _toEntity(row);
  }

  @override
  Future<AppWorkspace> createWorkspace(AppWorkspace workspace) async {
    await _database.into(_database.workspaces).insert(_toCompanion(workspace));
    return workspace;
  }

  @override
  Future<AppWorkspace> updateWorkspace(AppWorkspace workspace) async {
    final updated =
        await (_database.update(_database.workspaces)
              ..where((row) => row.id.equals(workspace.id)))
            .write(_toCompanion(workspace));
    if (updated == 0) throw Exception('Workspace not found');
    return workspace;
  }

  @override
  Future<void> deleteWorkspace(String id) async {
    final connectionIds = await _database.transaction(() async {
      final childQuery = _database.selectOnly(_database.connections)
        ..addColumns([_database.connections.id])
        ..where(_database.connections.workspaceId.equals(id));
      final children = await childQuery
          .map((row) => row.read(_database.connections.id)!)
          .get();
      await (_database.delete(
        _database.workspaces,
      )..where((row) => row.id.equals(id))).go();
      return children;
    });

    for (final connectionId in connectionIds) {
      await _credentialStore.deletePassword(connectionId);
    }
  }

  AppWorkspace _toEntity(WorkspaceRow row) => AppWorkspace(
    id: row.id,
    name: row.name,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  WorkspacesCompanion _toCompanion(AppWorkspace workspace) =>
      WorkspacesCompanion.insert(
        id: workspace.id,
        name: workspace.name,
        createdAt: workspace.createdAt,
        updatedAt: workspace.updatedAt,
      );
}
