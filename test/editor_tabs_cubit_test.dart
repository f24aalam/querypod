import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/editor/domain/entities/connection_table.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_cubit.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_state.dart';

void main() {
  const users = ConnectionTable(name: 'users', type: ConnectionTableType.table);
  const posts = ConnectionTable(name: 'posts', type: ConnectionTableType.table);

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
    expect(cubit.state.previewTabKey, cubit.state.tabs.last.key);
  });

  test('double-clicking a preview tab pins and activates it', () {
    final cubit = EditorTabsCubit();
    cubit.openTablePreview(
      connectionId: 'connection',
      database: 'app',
      table: users,
    );

    final previewKey = cubit.state.activeTabKey!;
    cubit.pinTab(previewKey);

    expect(cubit.state.activeTabKey, previewKey);
    expect(cubit.state.activeTab?.isPinned, isTrue);
    expect(cubit.state.previewTabKey, isNull);
  });

  test('closing active tab selects the nearest tab', () {
    final cubit = EditorTabsCubit();
    cubit.openConnectionEditor();
    cubit.pinTable(connectionId: 'connection', database: 'app', table: users);

    cubit.closeTab(cubit.state.activeTabKey!);

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

  test('typed table keys cannot collide when names contain separators', () {
    final cubit = EditorTabsCubit();
    cubit.pinTable(
      connectionId: 'connection:one',
      database: 'database',
      table: users,
    );
    cubit.pinTable(
      connectionId: 'connection',
      database: 'one:database',
      table: users,
    );

    expect(cubit.state.tabs, hasLength(2));
    expect(cubit.state.tabs[0].key, isNot(cubit.state.tabs[1].key));
  });

  test('tab collections are externally immutable', () {
    final cubit = EditorTabsCubit()..openConnectionEditor();

    expect(
      () => cubit.state.tabs.add(cubit.state.tabs.single),
      throwsUnsupportedError,
    );
  });

  test('repeated activation does not emit another state', () async {
    final cubit = EditorTabsCubit()..openConnectionEditor();
    final emitted = <EditorTabsState>[];
    final subscription = cubit.stream.listen(emitted.add);

    cubit.activate(cubit.state.activeTabKey!);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isEmpty);
    await subscription.cancel();
  });

  test('saved connection synchronizes the editor title', () {
    final cubit = EditorTabsCubit()
      ..openConnectionEditor(
        connectionId: 'connection',
        connectionName: 'Old name',
      )
      ..syncConnectionEditor(
        connectionId: 'connection',
        connectionName: 'New name',
      );

    expect(cubit.state.tabs.single.title, 'New name');
    expect(cubit.state.tabs.single.connectionId, 'connection');
  });

  test('opening the same query reuses one tab and keeps it active', () {
    final cubit = EditorTabsCubit();

    cubit.openQuery(queryId: 'query_1', title: 'demo');
    cubit.openQuery(queryId: 'query_1', title: 'demo');

    expect(cubit.state.tabs, hasLength(1));
    expect(cubit.state.activeTab?.type, EditorTabType.query);
    expect(cubit.state.activeTab?.title, 'demo');
  });
}
