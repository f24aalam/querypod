import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/workspaces/data/repositories/workspace_repository_impl.dart';
import 'package:querypod/features/workspaces/domain/entities/app_workspace.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late WorkspaceRepositoryImpl repository;

  AppWorkspace workspace(
    String id,
    String name,
    DateTime createdAt,
  ) {
    return AppWorkspace(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = WorkspaceRepositoryImpl(prefs);
  });

  test('empty storage returns no workspaces', () async {
    expect(await repository.getWorkspaces(), isEmpty);
  });

  test('getWorkspaces sorts by createdAt descending', () async {
    final older = workspace('older', 'Older', DateTime(2024, 1, 1));
    final newer = workspace('newer', 'Newer', DateTime(2025, 1, 1));

    await repository.createWorkspace(older);
    await repository.createWorkspace(newer);

    final workspaces = await repository.getWorkspaces();
    expect(workspaces.map((item) => item.id).toList(), ['newer', 'older']);
  });

  test('getWorkspace returns the matching workspace', () async {
    final target = workspace('target', 'Target', DateTime(2024, 2, 1));
    await repository.createWorkspace(target);

    expect(await repository.getWorkspace('target'), target);
  });

  test('getWorkspace throws when the workspace is missing', () async {
    expect(
      () => repository.getWorkspace('missing'),
      throwsA(isA<Exception>()),
    );
  });

  test('createWorkspace persists the workspace', () async {
    final created = workspace('created', 'Created', DateTime(2024, 3, 1));

    await repository.createWorkspace(created);

    expect(await repository.getWorkspaces(), [created]);
  });

  test('updateWorkspace replaces only the matching workspace', () async {
    final first = workspace('first', 'First', DateTime(2024, 1, 1));
    final second = workspace('second', 'Second', DateTime(2024, 2, 1));
    await repository.createWorkspace(first);
    await repository.createWorkspace(second);
    final updatedSecond = second.copyWith(name: 'Renamed');

    await repository.updateWorkspace(updatedSecond);

    final workspaces = await repository.getWorkspaces();
    expect(workspaces, [updatedSecond, first]);
  });

  test('updateWorkspace throws when the workspace does not exist', () async {
    final missing = workspace('missing', 'Missing', DateTime(2024, 1, 1));

    expect(
      () => repository.updateWorkspace(missing),
      throwsA(isA<Exception>()),
    );
  });

  test('deleteWorkspace removes only the target workspace', () async {
    final first = workspace('first', 'First', DateTime(2024, 1, 1));
    final second = workspace('second', 'Second', DateTime(2024, 2, 1));
    await repository.createWorkspace(first);
    await repository.createWorkspace(second);

    await repository.deleteWorkspace('first');

    expect(await repository.getWorkspaces(), [second]);
  });

  test('keyNamespace isolates workspace storage', () async {
    final defaultRepository = WorkspaceRepositoryImpl(prefs);
    final alphaRepository = WorkspaceRepositoryImpl(prefs, keyNamespace: 'alpha');
    final betaRepository = WorkspaceRepositoryImpl(prefs, keyNamespace: 'beta');

    await defaultRepository.createWorkspace(
      workspace('default', 'Default', DateTime(2024, 1, 1)),
    );
    await alphaRepository.createWorkspace(
      workspace('alpha', 'Alpha', DateTime(2024, 2, 1)),
    );

    expect(
      (await defaultRepository.getWorkspaces()).map((item) => item.id).toList(),
      ['default'],
    );
    expect(
      (await alphaRepository.getWorkspaces()).map((item) => item.id).toList(),
      ['alpha'],
    );
    expect(await betaRepository.getWorkspaces(), isEmpty);
  });
}
