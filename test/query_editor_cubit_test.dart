import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/workspace/domain/entities/workspace_query.dart';
import 'package:querypod/features/workspace/domain/repositories/query_repository.dart';
import 'package:querypod/features/workspace/presentation/cubit/query_editor_cubit.dart';

void main() {
  test(
    'loadConnection hydrates persisted queries for one connection',
    () async {
      final repository = _InMemoryQueryRepository(
        seeded: [
          _query(id: 'q1', connectionId: 'conn-1', title: 'demo'),
          _query(id: 'q2', connectionId: 'conn-2', title: 'other'),
        ],
      );
      final cubit = QueryEditorCubit(repository: repository);

      await cubit.loadConnection('conn-1');

      expect(cubit.state.connectionId, 'conn-1');
      expect(cubit.state.queries, hasLength(1));
      expect(cubit.state.queries.single.title, 'demo');
      await cubit.close();
    },
  );

  test(
    'createQuery persists a new demo query for the active connection',
    () async {
      final repository = _InMemoryQueryRepository();
      final cubit = QueryEditorCubit(repository: repository);
      await cubit.loadConnection('conn-1');

      final query = await cubit.createQuery();

      expect(query.connectionId, 'conn-1');
      expect(query.title, 'demo');
      expect(repository.saved.last.connectionId, 'conn-1');
      expect(repository.saved.last.title, 'demo');
      await cubit.close();
    },
  );

  test('renameQuery persists the new title', () async {
    final existing = _query(id: 'q1', connectionId: 'conn-1', title: 'demo');
    final repository = _InMemoryQueryRepository(seeded: [existing]);
    final cubit = QueryEditorCubit(repository: repository);
    await cubit.loadConnection('conn-1');

    await cubit.renameQuery('q1', 'renamed');

    expect(cubit.state.queries.single.title, 'renamed');
    expect(repository.byId('q1')?.title, 'renamed');
    await cubit.close();
  });

  test('deleteQuery removes the query from state and repository', () async {
    final repository = _InMemoryQueryRepository(
      seeded: [_query(id: 'q1', connectionId: 'conn-1', title: 'demo')],
    );
    final cubit = QueryEditorCubit(repository: repository);
    await cubit.loadConnection('conn-1');

    await cubit.deleteQuery('q1');

    expect(cubit.state.queries, isEmpty);
    expect(repository.byId('q1'), isNull);
    await cubit.close();
  });

  test('editing a query autosaves its sql text', () async {
    final repository = _InMemoryQueryRepository(
      seeded: [_query(id: 'q1', connectionId: 'conn-1', title: 'demo')],
    );
    final cubit = QueryEditorCubit(repository: repository);
    await cubit.loadConnection('conn-1');

    cubit.state.queries.single.controller.fullText = 'SELECT id FROM users;';
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(repository.byId('q1')?.sql, 'SELECT id FROM users;');
    await cubit.close();
  });
}

WorkspaceQuery _query({
  required String id,
  required String connectionId,
  required String title,
  String sql = 'SELECT * FROM users;',
}) {
  final now = DateTime(2026, 1, 1);
  return WorkspaceQuery(
    id: id,
    connectionId: connectionId,
    title: title,
    sql: sql,
    createdAt: now,
    updatedAt: now,
  );
}

class _InMemoryQueryRepository implements QueryRepository {
  final Map<String, WorkspaceQuery> _queries;
  final List<WorkspaceQuery> saved = [];

  _InMemoryQueryRepository({List<WorkspaceQuery> seeded = const []})
    : _queries = {for (final query in seeded) query.id: query};

  WorkspaceQuery? byId(String id) => _queries[id];

  @override
  Future<void> delete(String id) async {
    _queries.remove(id);
  }

  @override
  Future<void> deleteByConnection(String connectionId) async {
    _queries.removeWhere((_, query) => query.connectionId == connectionId);
  }

  @override
  Future<List<WorkspaceQuery>> getAllForConnection(String connectionId) async {
    return _queries.values
        .where((query) => query.connectionId == connectionId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<WorkspaceQuery> save(WorkspaceQuery query) async {
    _queries[query.id] = query;
    saved.add(query);
    return query;
  }
}
