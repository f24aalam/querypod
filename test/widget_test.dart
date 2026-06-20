import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:querypod/app/app.dart';
import 'package:querypod/app/injection.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_editor_cubit.dart';
import 'package:querypod/features/connections/presentation/widgets/connection_form.dart';
import 'package:querypod/features/workspace/domain/entities/workspace_table.dart';
import 'package:querypod/features/workspace/presentation/cubit/editor_tabs_cubit.dart';
import 'package:querypod/features/workspace/presentation/cubit/editor_tabs_state.dart';
import 'package:querypod/features/workspace/presentation/pages/workspace_page.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(App), findsOneWidget);
  });

  testWidgets('only the active editor is mounted', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(WorkspacePage));
    final tabs = context.read<EditorTabsCubit>();

    tabs.openConnectionEditor();
    expect(tabs.state.activeTab, isNotNull);
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionForm), findsOneWidget);

    tabs.pinTable(
      connectionId: 'connection',
      database: 'app',
      table: const WorkspaceTable(
        name: 'users',
        type: WorkspaceTableType.table,
      ),
    );
    expect(tabs.state.activeTab?.title, 'users');
    await tester.pumpAndSettle();

    expect(find.byType(ConnectionForm), findsNothing);
    expect(find.text('Table rows coming next'), findsOneWidget);
  });

  testWidgets('opening an overflowed tab scrolls it into view', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(WorkspacePage));
    final tabs = context.read<EditorTabsCubit>();

    for (var i = 0; i < 8; i++) {
      tabs.pinTable(
        connectionId: 'connection',
        database: 'app',
        table: WorkspaceTable(name: 'table_$i', type: WorkspaceTableType.table),
      );
    }
    await tester.pumpAndSettle();

    const activeKey = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'table_7',
    );
    final tabRect = tester.getRect(
      find.byKey(
        const ValueKey<(String, EditorTabKey)>(('tab-strip', activeKey)),
      ),
    );
    final logicalWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;

    expect(tabRect.left, greaterThanOrEqualTo(0));
    expect(tabRect.right, lessThanOrEqualTo(logicalWidth));
  });

  testWidgets('connection draft survives tab switches and guards closing', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(WorkspacePage));
    final tabs = context.read<EditorTabsCubit>();

    tabs.openConnectionEditor();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(FTextField).first, 'Unsaved draft');
    await tester.pump();
    expect(context.read<ConnectionEditorCubit>().state.isDirty, isTrue);

    tabs.pinTable(
      connectionId: 'connection',
      database: 'app',
      table: const WorkspaceTable(
        name: 'users',
        type: WorkspaceTableType.table,
      ),
    );
    await tester.pumpAndSettle();
    tabs.activate(EditorTabsCubit.connectionEditorKey);
    await tester.pumpAndSettle();

    expect(find.text('Unsaved draft'), findsOneWidget);
    expect(context.read<ConnectionEditorCubit>().state.isDirty, isTrue);

    final connectionTab = find.byKey(
      const ValueKey<(String, EditorTabKey)>((
        'tab-strip',
        EditorTabsCubit.connectionEditorKey,
      )),
    );
    final connectionClose = find.descendant(
      of: connectionTab,
      matching: find.byType(IconButton),
    );

    await tester.tap(connectionClose);
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      tabs.state.tabs.any(
        (tab) => tab.key == EditorTabsCubit.connectionEditorKey,
      ),
      isTrue,
    );

    await tester.tap(connectionClose);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(
      tabs.state.tabs.any(
        (tab) => tab.key == EditorTabsCubit.connectionEditorKey,
      ),
      isFalse,
    );
  });
}
