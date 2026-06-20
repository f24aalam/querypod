import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workspace_table.dart';
import 'editor_tabs_state.dart';

class EditorTabsCubit extends Cubit<EditorTabsState> {
  static const connectionEditorId = 'connection-editor';

  EditorTabsCubit() : super(const EditorTabsState());

  void openConnectionEditor({String? connectionId, String? connectionName}) {
    final title = connectionName ?? 'New Connection';
    final index = state.tabs.indexWhere((tab) => tab.id == connectionEditorId);
    final tabs = List<EditorTab>.from(state.tabs);

    final tab = EditorTab(
      id: connectionEditorId,
      type: EditorTabType.connection,
      title: title,
      connectionId: connectionId,
    );

    if (index == -1) {
      tabs.add(tab);
    } else {
      tabs[index] = tab;
    }

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabId: connectionEditorId,
        previewTabId: state.previewTabId,
      ),
    );
  }

  void openTablePreview({
    required String connectionId,
    required String database,
    required WorkspaceTable table,
  }) {
    final id = _tableId(connectionId, database, table.name);
    final existing = state.tabs.where((tab) => tab.id == id).firstOrNull;

    if (existing != null) {
      emit(
        EditorTabsState(
          tabs: state.tabs,
          activeTabId: id,
          previewTabId: existing.isPinned ? state.previewTabId : id,
        ),
      );
      return;
    }

    final tabs = state.tabs
        .where((tab) => tab.id != state.previewTabId)
        .toList();
    tabs.add(
      EditorTab(
        id: id,
        type: EditorTabType.table,
        title: table.name,
        connectionId: connectionId,
        database: database,
        tableType: table.type,
        isPinned: false,
      ),
    );

    emit(EditorTabsState(tabs: tabs, activeTabId: id, previewTabId: id));
  }

  void pinTable({
    required String connectionId,
    required String database,
    required WorkspaceTable table,
  }) {
    final id = _tableId(connectionId, database, table.name);
    final index = state.tabs.indexWhere((tab) => tab.id == id);
    final tabs = List<EditorTab>.from(state.tabs);

    if (index == -1) {
      tabs.add(
        EditorTab(
          id: id,
          type: EditorTabType.table,
          title: table.name,
          connectionId: connectionId,
          database: database,
          tableType: table.type,
        ),
      );
    } else {
      tabs[index] = tabs[index].copyWith(isPinned: true);
    }

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabId: id,
        previewTabId: state.previewTabId == id ? null : state.previewTabId,
      ),
    );
  }

  void activate(String id) {
    if (!state.tabs.any((tab) => tab.id == id)) return;
    emit(
      EditorTabsState(
        tabs: state.tabs,
        activeTabId: id,
        previewTabId: state.previewTabId,
      ),
    );
  }

  void pinTab(String id) {
    final index = state.tabs.indexWhere((tab) => tab.id == id);
    if (index == -1) return;

    final tab = state.tabs[index];
    if (tab.type != EditorTabType.table || tab.isPinned) {
      activate(id);
      return;
    }

    final tabs = List<EditorTab>.from(state.tabs);
    tabs[index] = tab.copyWith(isPinned: true);
    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabId: id,
        previewTabId: state.previewTabId == id ? null : state.previewTabId,
      ),
    );
  }

  void closeTab(String id) {
    final index = state.tabs.indexWhere((tab) => tab.id == id);
    if (index == -1) return;

    final tabs = List<EditorTab>.from(state.tabs)..removeAt(index);
    var activeTabId = state.activeTabId;
    if (activeTabId == id) {
      activeTabId = tabs.isEmpty
          ? null
          : tabs[index.clamp(0, tabs.length - 1)].id;
    }

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabId: activeTabId,
        previewTabId: state.previewTabId == id ? null : state.previewTabId,
      ),
    );
  }

  void closeTableTabs() {
    final tabs = state.tabs
        .where((tab) => tab.type != EditorTabType.table)
        .toList();
    final activeStillExists = tabs.any((tab) => tab.id == state.activeTabId);

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabId: activeStillExists
            ? state.activeTabId
            : (tabs.isEmpty ? null : tabs.last.id),
      ),
    );
  }

  String _tableId(String connectionId, String database, String table) {
    return 'table:$connectionId:$database:$table';
  }
}
