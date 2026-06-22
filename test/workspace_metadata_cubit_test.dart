import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/workspace/domain/entities/workspace_database.dart';
import 'package:querypod/features/workspace/domain/entities/workspace_table.dart';
import 'package:querypod/features/workspace/domain/repositories/workspace_metadata_repository.dart';
import 'package:querypod/features/workspace/presentation/cubit/workspace_metadata_cubit.dart';
import 'package:querypod/features/workspace/domain/entities/table_data.dart';

void main() {
  const firstConnection = Connection(
    id: 'same-id',
    name: 'First',
    host: 'first',
    port: 3306,
    user: 'root',
    password: '',
    database: '',
  );
  const secondConnection = Connection(
    id: 'same-id',
    name: 'Second',
    host: 'second',
    port: 3306,
    user: 'root',
    password: '',
    database: '',
  );

  test(
    'stale connection metadata cannot replace the current session',
    () async {
      final repository = _ControlledRepository();
      final cubit = WorkspaceMetadataCubit(repository: repository);

      final firstLoad = cubit.loadConnection(firstConnection);
      final secondLoad = cubit.loadConnection(secondConnection);

      repository.databases['second']!.complete([
        const WorkspaceDatabase(name: 'current_db'),
      ]);
      await Future<void>.delayed(Duration.zero);
      repository.tables['current_db']!.complete([
        const WorkspaceTable(
          name: 'current_table',
          type: WorkspaceTableType.table,
        ),
      ]);
      await secondLoad;

      repository.databases['first']!.complete([
        const WorkspaceDatabase(name: 'stale_db'),
      ]);
      await firstLoad;

      expect(cubit.state.connectionSession, secondConnection.sessionIdentity);
      expect(cubit.state.selectedDatabase, 'current_db');
      expect(cubit.state.tables.single.name, 'current_table');
    },
  );

  test('stale request errors do not produce feedback', () async {
    final repository = _ControlledRepository();
    final cubit = WorkspaceMetadataCubit(repository: repository);

    final firstLoad = cubit.loadConnection(firstConnection);
    final secondLoad = cubit.loadConnection(secondConnection);
    repository.databases['second']!.complete(const []);
    await secondLoad;
    repository.databases['first']!.completeError(Exception('stale failure'));
    await firstLoad;

    expect(cubit.state.connectionSession, secondConnection.sessionIdentity);
    expect(cubit.state.feedbackNonce, 0);
    expect(cubit.state.feedbackMessage, isNull);
  });

  test('stale table results cannot replace a newer database', () async {
    final repository = _DatabaseSwitchRepository();
    final cubit = WorkspaceMetadataCubit(repository: repository);

    final initialLoad = cubit.loadConnection(firstConnection);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.selectedDatabase, 'first_db');

    final switchLoad = cubit.selectDatabase(firstConnection, 'second_db');
    repository.tables['second_db']!.complete([
      const WorkspaceTable(
        name: 'current_table',
        type: WorkspaceTableType.table,
      ),
    ]);
    await switchLoad;
    repository.tables['first_db']!.complete([
      const WorkspaceTable(name: 'stale_table', type: WorkspaceTableType.table),
    ]);
    await initialLoad;

    expect(cubit.state.selectedDatabase, 'second_db');
    expect(cubit.state.tables.single.name, 'current_table');
  });
}

class _ControlledRepository implements WorkspaceMetadataRepository {
  final databases = <String, Completer<List<WorkspaceDatabase>>>{};
  final tables = <String, Completer<List<WorkspaceTable>>>{};

  @override
  Future<List<WorkspaceDatabase>> listDatabases(Connection connection) {
    return (databases[connection.host] ??= Completer<List<WorkspaceDatabase>>())
        .future;
  }

  @override
  Future<List<WorkspaceTable>> listTables(
    Connection connection,
    String database,
  ) {
    return (tables[database] ??= Completer<List<WorkspaceTable>>()).future;
  }

  @override
  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {}

  @override
  Future<void> createTable(
    Connection connection,
    String database,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {}
}

class _DatabaseSwitchRepository implements WorkspaceMetadataRepository {
  final tables = <String, Completer<List<WorkspaceTable>>>{};

  @override
  Future<List<WorkspaceDatabase>> listDatabases(Connection connection) async {
    return const [
      WorkspaceDatabase(name: 'first_db'),
      WorkspaceDatabase(name: 'second_db'),
    ];
  }

  @override
  Future<List<WorkspaceTable>> listTables(
    Connection connection,
    String database,
  ) {
    return (tables[database] ??= Completer<List<WorkspaceTable>>()).future;
  }

  @override
  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {}

  @override
  Future<void> createTable(
    Connection connection,
    String database,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {}
}
