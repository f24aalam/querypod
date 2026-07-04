import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/workspaces/domain/entities/app_workspace.dart';
import 'package:querypod/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:querypod/features/workspaces/presentation/cubit/workspaces_cubit.dart';
import 'package:querypod/features/workspaces/presentation/cubit/workspaces_state.dart';

void main() {
  AppWorkspace workspace({
    String id = 'workspace-1',
    String name = 'Workspace 1',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final created = createdAt ?? DateTime(2024, 1, 1);
    return AppWorkspace(
      id: id,
      name: name,
      createdAt: created,
      updatedAt: updatedAt ?? created,
    );
  }

  test('loadWorkspaces emits loading then loaded', () async {
    final repository = _FakeWorkspaceRepository(
      workspaces: [workspace(id: 'a'), workspace(id: 'b')],
    );
    final cubit = WorkspacesCubit(repository: repository);

    final future = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<WorkspacesLoading>(),
        isA<WorkspacesLoaded>().having(
          (state) => state.workspaces.map((item) => item.id).toList(),
          'workspace ids',
          ['a', 'b'],
        ),
      ]),
    );

    await cubit.loadWorkspaces();
    await future;
    await cubit.close();
  });

  test('loadWorkspaces emits error when repository fails', () async {
    final cubit = WorkspacesCubit(
      repository: _FakeWorkspaceRepository(getWorkspacesError: Exception('boom')),
    );

    final future = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<WorkspacesLoading>(),
        isA<WorkspacesError>().having(
          (state) => state.message,
          'message',
          contains('boom'),
        ),
      ]),
    );

    await cubit.loadWorkspaces();
    await future;
    await cubit.close();
  });

  test('createWorkspace creates a new workspace and reloads state', () async {
    final repository = _FakeWorkspaceRepository();
    final cubit = WorkspacesCubit(repository: repository);

    await cubit.createWorkspace('New Workspace');

    expect(cubit.state, isA<WorkspacesLoaded>());
    final loaded = cubit.state as WorkspacesLoaded;
    expect(loaded.workspaces, hasLength(1));
    final created = loaded.workspaces.single;
    expect(created.id, isNotEmpty);
    expect(created.name, 'New Workspace');
    expect(created.createdAt, created.updatedAt);
    await cubit.close();
  });

  test('createWorkspace emits error when repository create fails', () async {
    final cubit = WorkspacesCubit(
      repository: _FakeWorkspaceRepository(createError: Exception('create failed')),
    );

    await cubit.createWorkspace('Broken');

    expect(cubit.state, isA<WorkspacesError>());
    expect((cubit.state as WorkspacesError).message, contains('create failed'));
    await cubit.close();
  });

  test('updateWorkspace refreshes updatedAt and reloads state', () async {
    final original = workspace(
      id: 'workspace-1',
      name: 'Original',
      createdAt: DateTime(2024, 1, 1),
    );
    final repository = _FakeWorkspaceRepository(workspaces: [original]);
    final cubit = WorkspacesCubit(repository: repository);

    await cubit.updateWorkspace(original.copyWith(name: 'Renamed'));

    final loaded = cubit.state as WorkspacesLoaded;
    final updated = loaded.workspaces.single;
    expect(updated.name, 'Renamed');
    expect(updated.updatedAt.isAfter(original.updatedAt), isTrue);
    await cubit.close();
  });

  test('updateWorkspace emits error when repository update fails', () async {
    final cubit = WorkspacesCubit(
      repository: _FakeWorkspaceRepository(updateError: Exception('update failed')),
    );

    await cubit.updateWorkspace(workspace());

    expect(cubit.state, isA<WorkspacesError>());
    expect((cubit.state as WorkspacesError).message, contains('update failed'));
    await cubit.close();
  });

  test('deleteWorkspace deletes then reloads state', () async {
    final first = workspace(id: 'first', name: 'First');
    final second = workspace(id: 'second', name: 'Second');
    final repository = _FakeWorkspaceRepository(workspaces: [first, second]);
    final cubit = WorkspacesCubit(repository: repository);

    await cubit.deleteWorkspace('first');

    final loaded = cubit.state as WorkspacesLoaded;
    expect(loaded.workspaces, [second]);
    await cubit.close();
  });

  test('deleteWorkspace emits error when repository delete fails', () async {
    final cubit = WorkspacesCubit(
      repository: _FakeWorkspaceRepository(deleteError: Exception('delete failed')),
    );

    await cubit.deleteWorkspace('first');

    expect(cubit.state, isA<WorkspacesError>());
    expect((cubit.state as WorkspacesError).message, contains('delete failed'));
    await cubit.close();
  });
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  _FakeWorkspaceRepository({
    List<AppWorkspace>? workspaces,
    this.getWorkspacesError,
    this.createError,
    this.updateError,
    this.deleteError,
  }) : _workspaces = [...?workspaces];

  final List<AppWorkspace> _workspaces;
  final Object? getWorkspacesError;
  final Object? createError;
  final Object? updateError;
  final Object? deleteError;

  @override
  Future<AppWorkspace> createWorkspace(AppWorkspace workspace) async {
    if (createError != null) throw createError!;
    _workspaces.add(workspace);
    return workspace;
  }

  @override
  Future<void> deleteWorkspace(String id) async {
    if (deleteError != null) throw deleteError!;
    _workspaces.removeWhere((workspace) => workspace.id == id);
  }

  @override
  Future<AppWorkspace> getWorkspace(String id) async {
    return _workspaces.firstWhere((workspace) => workspace.id == id);
  }

  @override
  Future<List<AppWorkspace>> getWorkspaces() async {
    if (getWorkspacesError != null) throw getWorkspacesError!;
    return List<AppWorkspace>.from(_workspaces);
  }

  @override
  Future<AppWorkspace> updateWorkspace(AppWorkspace workspace) async {
    if (updateError != null) throw updateError!;
    final index = _workspaces.indexWhere((item) => item.id == workspace.id);
    if (index == -1) throw Exception('Workspace not found');
    _workspaces[index] = workspace;
    return workspace;
  }
}
