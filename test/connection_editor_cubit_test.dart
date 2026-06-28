import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_editor_cubit.dart';

void main() {
  const connection = Connection(
    id: 'connection',
    name: 'Local',
    host: '127.0.0.1',
    port: 3306,
    user: 'root',
    password: '',
    database: 'app',
    workspaceId: 'default',
  );

  test('draft becomes dirty and survives independently of widgets', () {
    final cubit = ConnectionEditorCubit()..load(connection, activeWorkspaceId: 'default');

    cubit.updateHost('localhost');

    expect(cubit.state.isDirty, isTrue);
    expect(cubit.state.draft.host, 'localhost');
    expect(cubit.state.draft.sourceConnectionId, connection.id);
  });

  test('marking a saved draft resets dirty state', () {
    final cubit = ConnectionEditorCubit()
      ..load(connection, activeWorkspaceId: 'default')
      ..updateName('Renamed');
    final saved = cubit.state.draft.toConnection();

    cubit.markSaved(saved);

    expect(cubit.state.isDirty, isFalse);
    expect(cubit.state.draft.name, 'Renamed');
  });

  test('new drafts retain one generated id while edited', () {
    final cubit = ConnectionEditorCubit();
    final id = cubit.state.draft.id;

    cubit.updateName('Unsaved');
    cubit.updateHost('localhost');

    expect(cubit.state.draft.id, id);
    expect(cubit.state.draft.toConnection().id, id);
  });

  test('TLS setting is editable and preserved when saved', () {
    final cubit = ConnectionEditorCubit()..load(connection, activeWorkspaceId: 'default');

    cubit.updateUseTls(false);

    expect(cubit.state.isDirty, isTrue);
    expect(cubit.state.draft.useTls, isFalse);
    expect(cubit.state.draft.toConnection().useTls, isFalse);
  });
}
