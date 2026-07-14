import 'package:drift/native.dart';
import 'package:querypod/app/database.dart';
import 'package:querypod/features/connections/data/services/connection_credential_store.dart';

QueryPodDatabase createTestDatabase() =>
    QueryPodDatabase(executor: NativeDatabase.memory());

class MemoryCredentialStore implements ConnectionCredentialStore {
  final Map<String, String> values;
  final String namespace;

  MemoryCredentialStore({Map<String, String>? values, this.namespace = ''})
    : values = values ?? <String, String>{};

  String keyFor(String connectionId) {
    final normalized = namespace.trim();
    return normalized.isEmpty ? connectionId : '$normalized::$connectionId';
  }

  @override
  Future<void> deletePassword(String connectionId) async {
    values.remove(keyFor(connectionId));
  }

  @override
  Future<String?> readPassword(String connectionId) async =>
      values[keyFor(connectionId)];

  @override
  Future<void> writePassword(String connectionId, String password) async {
    values[keyFor(connectionId)] = password;
  }
}

Future<void> seedWorkspace(
  QueryPodDatabase database, {
  String id = 'default',
}) async {
  final now = DateTime(2026, 1, 1);
  await database
      .into(database.workspaces)
      .insert(
        WorkspacesCompanion.insert(
          id: id,
          name: id,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> seedConnection(
  QueryPodDatabase database, {
  String id = 'connection',
  String workspaceId = 'default',
}) async {
  await database
      .into(database.connections)
      .insert(
        ConnectionsCompanion.insert(
          id: id,
          workspaceId: workspaceId,
          name: id,
          host: 'localhost',
          port: 5432,
          user: 'postgres',
          database: 'app',
          connectionType: 'postgresql',
          useTls: false,
        ),
      );
}
