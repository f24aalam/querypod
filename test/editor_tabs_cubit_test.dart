import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/workspace/domain/entities/workspace_table.dart';
import 'package:querypod/features/workspace/presentation/cubit/editor_tabs_cubit.dart';
import 'package:querypod/features/workspace/presentation/cubit/editor_tabs_state.dart';

void main() {
  const users = WorkspaceTable(name: 'users', type: WorkspaceTableType.table);
  const posts = WorkspaceTable(name: 'posts', type: WorkspaceTableType.table);

  test('single-click previews reuse one preview tab', () {
    final cubit = EditorTabsCubit();

    cubit.openTablePreview(
      connectionId: 'connection',
      database: 'app',
      table: users,
    );
    cubit.openTablePreview(
      connectionId: 'connection',
      database: 'app',
      table: posts,
    );

    expect(cubit.state.tabs, hasLength(1));
    expect(cubit.state.activeTab?.title, 'posts');
    expect(cubit.state.activeTab?.isPinned, isFalse);
  });

  test('double-click pins a preview and prevents replacement', () {
    final cubit = EditorTabsCubit();

    cubit.openTablePreview(
      connectionId: 'connection',
      database: 'app',
      table: users,
    );
    cubit.pinTable(connectionId: 'connection', database: 'app', table: users);
    cubit.openTablePreview(
      connectionId: 'connection',
      database: 'app',
      table: posts,
    );

    expect(cubit.state.tabs, hasLength(2));
    expect(cubit.state.tabs.first.isPinned, isTrue);
    expect(cubit.state.previewTabId, cubit.state.tabs.last.id);
  });

  test('double-clicking a preview tab pins and activates it', () {
    final cubit = EditorTabsCubit();
    cubit.openTablePreview(
      connectionId: 'connection',
      database: 'app',
      table: users,
    );

    final previewId = cubit.state.activeTabId!;
    cubit.pinTab(previewId);

    expect(cubit.state.activeTabId, previewId);
    expect(cubit.state.activeTab?.isPinned, isTrue);
    expect(cubit.state.previewTabId, isNull);
  });

  test('closing active tab selects the nearest tab', () {
    final cubit = EditorTabsCubit();
    cubit.openConnectionEditor();
    cubit.pinTable(connectionId: 'connection', database: 'app', table: users);

    cubit.closeTab(cubit.state.activeTabId!);

    expect(cubit.state.activeTab?.type, EditorTabType.connection);
  });

  test('changing connection removes table tabs only', () {
    final cubit = EditorTabsCubit();
    cubit.openConnectionEditor();
    cubit.pinTable(connectionId: 'connection', database: 'app', table: users);

    cubit.closeTableTabs();

    expect(cubit.state.tabs, hasLength(1));
    expect(cubit.state.tabs.single.type, EditorTabType.connection);
  });
}
