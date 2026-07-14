import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../../connections/presentation/cubit/connection_state.dart';
import 'dart:async';

import '../cubit/activity_cubit.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/query_editor_cubit.dart';
import '../cubit/query_editor_effects.dart';
import '../cubit/table_data_cubit.dart';
import '../cubit/connection_metadata_cubit.dart';
import '../cubit/connection_metadata_state.dart';
import '../widgets/activity_bar.dart';
import '../widgets/context_sidebar.dart';
import '../widgets/editor_area.dart';
import '../widgets/table_data_editor.dart';
import '../widgets/status_bar.dart';
import '../widgets/app_title_bar.dart';
import '../../../../core/keyboard/keyboard_shortcuts.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  ConnectionSessionIdentity? _loadedConnectionSession;
  Set<TableTabKey> _knownTableKeys = {};
  StreamSubscription<QueryEditorEffect>? _queryEditorEffectsSub;

  @override
  void initState() {
    super.initState();
    _queryEditorEffectsSub = context.read<QueryEditorCubit>().effects.listen((
      effect,
    ) {
      if (!mounted) return;
      if (effect is QueryExecutionError) {
        showFToast(
          context: context,
          variant: FToastVariant.destructive,
          title: Text(
            'Error executing query:\n${effect.errorMessage}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _queryEditorEffectsSub?.cancel();
    super.dispose();
  }

  void _handleShortcut(VoidCallback action) {
    // If a text field or code editor has focus, don't hijack its shortcuts (unless it's something they don't consume).
    // CallbackShortcuts automatically only fires if no child consumed the event, which is exactly what we want.
    action();
  }

  Future<void> _copyActiveTableSelection() async {
    final activeTab = context.read<EditorTabsCubit>().state.activeTabKey;
    if (activeTab is! TableTabKey) return;

    final session = context.read<TableDataCubit>().state.session(activeTab);
    if (session == null || session.selectedRowIndexes.isEmpty) return;

    final rowIndex = session.selectedRowIndexes.reduce((a, b) => a < b ? a : b);
    await Clipboard.setData(
      ClipboardData(text: formatCopiedTableRows(session, rowIndex)),
    );
    if (!mounted) return;
    showFToast(
      context: context,
      variant: FToastVariant.primary,
      title: const Text('Copied to clipboard'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _knownTableKeys = context
        .read<EditorTabsCubit>()
        .state
        .tabs
        .map((tab) => tab.key)
        .whereType<TableTabKey>()
        .toSet();
    _syncConnectionEditor(
      context.read<ConnectionCubit>().state.activeConnection,
    );
    context.read<QueryEditorCubit>().loadConnection(
      context.read<ConnectionCubit>().state.activeConnection?.id,
    );
  }

  void _syncConnectionEditor(Connection? connection) {
    final workspaceCubit = context.read<ConnectionMetadataCubit>();

    if (connection == null) {
      _loadedConnectionSession = null;
      workspaceCubit.clear();
      return;
    }

    final session = connection.sessionIdentity;
    if (_loadedConnectionSession == session &&
        workspaceCubit.state.connectionSession == session) {
      return;
    }

    _loadedConnectionSession = session;
    workspaceCubit.loadConnection(connection);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConnectionCubit, ConnectionsState>(
          listenWhen: (prev, curr) =>
              prev.activeConnection?.sessionIdentity !=
              curr.activeConnection?.sessionIdentity,
          listener: (context, state) {
            context.read<EditorTabsCubit>().closeTableTabs();
            context.read<EditorTabsCubit>().closeQueryTabs();
            context.read<TableDataCubit>().clear();
            _syncConnectionEditor(state.activeConnection);
            context.read<QueryEditorCubit>().loadConnection(
              state.activeConnection?.id,
            );
          },
        ),
        BlocListener<EditorTabsCubit, EditorTabsState>(
          listenWhen: (previous, current) => previous.tabs != current.tabs,
          listener: (context, state) {
            final currentKeys = state.tabs
                .map((tab) => tab.key)
                .whereType<TableTabKey>()
                .toSet();
            for (final key in _knownTableKeys) {
              if (!currentKeys.contains(key)) {
                context.read<TableDataCubit>().closeSession(key);
              }
            }
            _knownTableKeys = currentKeys;
          },
        ),
        BlocListener<ConnectionCubit, ConnectionsState>(
          listenWhen: (prev, curr) =>
              prev.openConnectionNonce != curr.openConnectionNonce,
          listener: (context, state) {
            context.read<ActivityCubit>().select(WorkbenchActivity.tables);
          },
        ),
        BlocListener<ConnectionMetadataCubit, ConnectionMetadataState>(
          listenWhen: (prev, curr) =>
              prev.feedbackNonce != curr.feedbackNonce &&
              curr.feedbackMessage != null,
          listener: (context, state) {
            showFToast(
              context: context,
              variant: state.feedbackIsError
                  ? FToastVariant.destructive
                  : FToastVariant.primary,
              title: Text(state.feedbackMessage!),
            );
          },
        ),
      ],
      child: CallbackShortcuts(
        bindings: {
          KeyboardShortcuts.commit: () => _handleShortcut(() {
            final activeTab = context
                .read<EditorTabsCubit>()
                .state
                .activeTabKey;
            if (activeTab is TableTabKey) {
              context.read<TableDataCubit>().commitPendingChanges(activeTab);
            }
          }),
          KeyboardShortcuts.cancel: () => _handleShortcut(() {
            final activeTab = context
                .read<EditorTabsCubit>()
                .state
                .activeTabKey;
            if (activeTab is TableTabKey) {
              final tableCubit = context.read<TableDataCubit>();
              final session = tableCubit.state.sessions[activeTab];
              if (session != null) {
                if (session.activeCellEdit != null) {
                  tableCubit.cancelActiveCellEdit(activeTab);
                } else if (session.foreignRowPreview != null) {
                  tableCubit.clearForeignRowPreview(activeTab);
                } else if (session.isShowingStructure) {
                  tableCubit.hideTableStructure(activeTab);
                } else if (session.hasSelection) {
                  tableCubit.clearSelection(activeTab);
                } else {
                  tableCubit.clearPendingChanges(activeTab);
                }
              }
            }
          }),
          KeyboardShortcuts.copy: () =>
              _handleShortcut(() => unawaited(_copyActiveTableSelection())),
          KeyboardShortcuts.newRow: () => _handleShortcut(() {
            final activeTab = context
                .read<EditorTabsCubit>()
                .state
                .activeTabKey;
            if (activeTab is TableTabKey) {
              context.read<TableDataCubit>().stageInsert(activeTab);
            }
          }),
          KeyboardShortcuts.createTable: () => _handleShortcut(() {
            final connection = context
                .read<ConnectionCubit>()
                .state
                .activeConnection;
            if (connection != null) {
              context.read<EditorTabsCubit>().openCreateTableTab(
                connectionId: connection.id,
                database: connection.database,
              );
            }
          }),
          KeyboardShortcuts.refresh: () => _handleShortcut(() {
            final activeTab = context
                .read<EditorTabsCubit>()
                .state
                .activeTabKey;
            if (activeTab is TableTabKey) {
              context.read<TableDataCubit>().refresh(activeTab);
            } else if (activeTab is QueryTabKey) {
              context.read<QueryEditorCubit>().runQuery(activeTab.queryId);
            }
          }),
          KeyboardShortcuts.refreshF5: () => _handleShortcut(() {
            final activeTab = context
                .read<EditorTabsCubit>()
                .state
                .activeTabKey;
            if (activeTab is TableTabKey) {
              context.read<TableDataCubit>().refresh(activeTab);
            } else if (activeTab is QueryTabKey) {
              context.read<QueryEditorCubit>().runQuery(activeTab.queryId);
            }
          }),
          KeyboardShortcuts.newQuery: () => _handleShortcut(() async {
            final tabsCubit = context.read<EditorTabsCubit>();
            final query = await context.read<QueryEditorCubit>().createQuery();
            tabsCubit.openQuery(queryId: query.id, title: query.title);
          }),
          KeyboardShortcuts.connectionsSidebar: () => _handleShortcut(() {
            context.read<ActivityCubit>().select(WorkbenchActivity.connections);
          }),
          KeyboardShortcuts.tablesSidebar: () => _handleShortcut(() {
            context.read<ActivityCubit>().select(WorkbenchActivity.tables);
          }),
          KeyboardShortcuts.historySidebar: () => _handleShortcut(() {
            context.read<ActivityCubit>().select(WorkbenchActivity.history);
          }),
          KeyboardShortcuts.querySidebar: () => _handleShortcut(() {
            context.read<ActivityCubit>().select(WorkbenchActivity.query);
          }),
          KeyboardShortcuts.nextTab: () => _handleShortcut(() {
            context.read<EditorTabsCubit>().activateNextTab();
          }),
          KeyboardShortcuts.previousTab: () => _handleShortcut(() {
            context.read<EditorTabsCubit>().activatePreviousTab();
          }),
          KeyboardShortcuts.closeTab: () => _handleShortcut(() {
            final activeTab = context
                .read<EditorTabsCubit>()
                .state
                .activeTabKey;
            if (activeTab != null) {
              context.read<EditorTabsCubit>().closeTab(activeTab);
            }
          }),
        },
        child: Focus(
          autofocus: true,
          child: ColoredBox(
            color: context.theme.colors.background,
            child: Column(
              children: [
                const AppTitleBar(),
                Expanded(
                  child: Row(
                    children: [
                      BlocBuilder<ConnectionCubit, ConnectionsState>(
                        buildWhen: (prev, curr) =>
                            prev.activeConnection?.sessionIdentity !=
                            curr.activeConnection?.sessionIdentity,
                        builder: (context, state) => ActivityBar(
                          canOpenEditor: state.activeConnection != null,
                        ),
                      ),
                      Expanded(
                        child: FResizable(
                          axis: Axis.horizontal,
                          children: [
                            FResizableRegion.fixed(
                              extent: 280,
                              minExtent: 160,
                              builder: (context, data, child) => child!,
                              child: const ContextSidebar(),
                            ),
                            FResizableRegion.flex(
                              flex: 1,
                              minFlex: 1,
                              builder: (context, data, child) => child!,
                              child: const EditorArea(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.theme.colors.border,
                ),
                const StatusBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
