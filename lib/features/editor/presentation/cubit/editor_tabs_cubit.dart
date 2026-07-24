import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/connection_table.dart';
import 'editor_tabs_state.dart';

class EditorTabsCubit extends Cubit<EditorTabsState> {
  static const connectionEditorKey = ConnectionEditorTabKey();

  EditorTabsCubit() : super(EditorTabsState());

  void openConnectionEditor({String? connectionId, String? connectionName}) {
    final title = connectionName ?? 'New Connection';
    final index = state.tabs.indexWhere(
      (tab) => tab.key == connectionEditorKey,
    );
    final tab = EditorTab(
      key: connectionEditorKey,
      type: EditorTabType.connection,
      title: title,
      connectionId: connectionId,
    );

    if (index >= 0 &&
        state.tabs[index] == tab &&
        state.activeTabKey == connectionEditorKey) {
      return;
    }

    final tabs = List<EditorTab>.from(state.tabs);
    if (index == -1) {
      tabs.add(tab);
    } else {
      tabs[index] = tab;
    }

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: connectionEditorKey,
        previewTabKey: state.previewTabKey,
      ),
    );
  }

  void syncConnectionEditor({
    required String connectionId,
    required String connectionName,
  }) {
    final index = state.tabs.indexWhere(
      (tab) => tab.key == connectionEditorKey,
    );
    if (index == -1) return;

    final updated = state.tabs[index].copyWith(
      title: connectionName,
      connectionId: () => connectionId,
    );
    if (updated == state.tabs[index]) return;

    final tabs = List<EditorTab>.from(state.tabs)..[index] = updated;
    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: state.activeTabKey,
        previewTabKey: state.previewTabKey,
      ),
    );
  }

  void renameQueryTab({required String queryId, required String title}) {
    final key = QueryTabKey(queryId: queryId);
    final index = state.tabs.indexWhere((tab) => tab.key == key);
    if (index == -1) return;

    final updated = state.tabs[index].copyWith(title: title);
    if (updated == state.tabs[index]) return;

    final tabs = List<EditorTab>.from(state.tabs)..[index] = updated;
    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: state.activeTabKey,
        previewTabKey: state.previewTabKey,
      ),
    );
  }

  void openQuery({required String queryId, required String title}) {
    final key = QueryTabKey(queryId: queryId);
    final index = state.tabs.indexWhere((tab) => tab.key == key);
    final tabs = List<EditorTab>.from(state.tabs);
    final tab = EditorTab(key: key, type: EditorTabType.query, title: title);

    if (index == -1) {
      tabs.add(tab);
    } else {
      if (state.tabs[index] == tab && state.activeTabKey == key) return;
      tabs[index] = tab;
    }

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: key,
        previewTabKey: state.previewTabKey,
      ),
    );
  }

  void openTablePreview({
    required String connectionId,
    required String database,
    String? schema,
    required ConnectionTable table,
  }) {
    final key = TableTabKey(
      connectionId: connectionId,
      database: database,
      schema: schema,
      tableName: table.name,
    );
    final existing = state.tabs.where((tab) => tab.key == key).firstOrNull;

    if (existing != null) {
      final previewKey = existing.isPinned ? state.previewTabKey : key;
      if (state.activeTabKey == key && state.previewTabKey == previewKey) {
        return;
      }
      emit(
        EditorTabsState(
          tabs: state.tabs,
          activeTabKey: key,
          previewTabKey: previewKey,
        ),
      );
      return;
    }

    final tabs =
        state.tabs.where((tab) => tab.key != state.previewTabKey).toList()..add(
          EditorTab(
            key: key,
            type: EditorTabType.table,
            title: _tableTitle(table.name, schema),
            connectionId: connectionId,
            database: database,
            schema: schema,
            tableType: table.type,
            isPinned: false,
          ),
        );

    emit(EditorTabsState(tabs: tabs, activeTabKey: key, previewTabKey: key));
  }

  void pinTable({
    required String connectionId,
    required String database,
    String? schema,
    required ConnectionTable table,
  }) {
    final key = TableTabKey(
      connectionId: connectionId,
      database: database,
      schema: schema,
      tableName: table.name,
    );
    final index = state.tabs.indexWhere((tab) => tab.key == key);
    final tabs = List<EditorTab>.from(state.tabs);

    if (index == -1) {
      tabs.add(
        EditorTab(
          key: key,
          type: EditorTabType.table,
          title: _tableTitle(table.name, schema),
          connectionId: connectionId,
          database: database,
          schema: schema,
          tableType: table.type,
        ),
      );
    } else if (!tabs[index].isPinned) {
      tabs[index] = tabs[index].copyWith(isPinned: true);
    } else if (state.activeTabKey == key) {
      return;
    }

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: key,
        previewTabKey: state.previewTabKey == key ? null : state.previewTabKey,
      ),
    );
  }

  void activate(EditorTabKey key) {
    if (state.activeTabKey == key) return;
    if (!state.tabs.any((tab) => tab.key == key)) return;
    emit(
      EditorTabsState(
        tabs: state.tabs,
        activeTabKey: key,
        previewTabKey: state.previewTabKey,
      ),
    );
  }

  void activateNextTab() {
    if (state.tabs.isEmpty) return;
    final currentIndex = state.tabs.indexWhere(
      (tab) => tab.key == state.activeTabKey,
    );
    if (currentIndex == -1) return;
    final nextIndex = (currentIndex + 1) % state.tabs.length;
    activate(state.tabs[nextIndex].key);
  }

  void activatePreviousTab() {
    if (state.tabs.isEmpty) return;
    final currentIndex = state.tabs.indexWhere(
      (tab) => tab.key == state.activeTabKey,
    );
    if (currentIndex == -1) return;
    final previousIndex =
        (currentIndex - 1 + state.tabs.length) % state.tabs.length;
    activate(state.tabs[previousIndex].key);
  }

  void pinTab(EditorTabKey key) {
    final index = state.tabs.indexWhere((tab) => tab.key == key);
    if (index == -1) return;

    final tab = state.tabs[index];
    if (tab.type != EditorTabType.table || tab.isPinned) {
      activate(key);
      return;
    }

    final tabs = List<EditorTab>.from(state.tabs);
    tabs[index] = tab.copyWith(isPinned: true);
    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: key,
        previewTabKey: state.previewTabKey == key ? null : state.previewTabKey,
      ),
    );
  }

  void closeTab(EditorTabKey key) {
    final index = state.tabs.indexWhere((tab) => tab.key == key);
    if (index == -1) return;

    final tabs = List<EditorTab>.from(state.tabs)..removeAt(index);
    var activeTabKey = state.activeTabKey;
    if (activeTabKey == key) {
      activeTabKey = tabs.isEmpty
          ? null
          : tabs[index.clamp(0, tabs.length - 1)].key;
    }

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: activeTabKey,
        previewTabKey: state.previewTabKey == key ? null : state.previewTabKey,
      ),
    );
  }

  void closeWorkTabs() {
    _closeTabsWhere((tab, index) => _isWorkTab(tab));
  }

  void closeWorkTabsToRight(EditorTabKey key) {
    final index = state.tabs.indexWhere((tab) => tab.key == key);
    if (index == -1) return;

    _closeTabsWhere((tab, tabIndex) => tabIndex > index && _isWorkTab(tab));
  }

  void closeWorkTabsToLeft(EditorTabKey key) {
    final index = state.tabs.indexWhere((tab) => tab.key == key);
    if (index == -1) return;

    _closeTabsWhere((tab, tabIndex) => tabIndex < index && _isWorkTab(tab));
  }

  void closeQueryTab(String queryId) {
    closeTab(QueryTabKey(queryId: queryId));
  }

  void closeTableTabs() {
    if (!state.tabs.any((tab) => tab.type == EditorTabType.table)) return;

    final tabs = state.tabs
        .where((tab) => tab.type != EditorTabType.table)
        .toList();
    final activeStillExists = tabs.any((tab) => tab.key == state.activeTabKey);

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: activeStillExists
            ? state.activeTabKey
            : (tabs.isEmpty ? null : tabs.last.key),
      ),
    );
  }

  void closeQueryTabs() {
    if (!state.tabs.any((tab) => tab.type == EditorTabType.query)) return;

    final tabs = state.tabs
        .where((tab) => tab.type != EditorTabType.query)
        .toList();
    final activeStillExists = tabs.any((tab) => tab.key == state.activeTabKey);

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: activeStillExists
            ? state.activeTabKey
            : (tabs.isEmpty ? null : tabs.last.key),
      ),
    );
  }

  void _closeTabsWhere(bool Function(EditorTab tab, int index) shouldClose) {
    final closingKeys = <EditorTabKey>{};
    final tabs = <EditorTab>[];

    for (var i = 0; i < state.tabs.length; i++) {
      final tab = state.tabs[i];
      if (shouldClose(tab, i)) {
        closingKeys.add(tab.key);
      } else {
        tabs.add(tab);
      }
    }

    if (closingKeys.isEmpty) return;

    final activeTabKey = _resolveActiveTabAfterClose(tabs, closingKeys);
    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: activeTabKey,
        previewTabKey: closingKeys.contains(state.previewTabKey)
            ? null
            : state.previewTabKey,
      ),
    );
  }

  EditorTabKey? _resolveActiveTabAfterClose(
    List<EditorTab> remainingTabs,
    Set<EditorTabKey> closingKeys,
  ) {
    if (state.activeTabKey != null &&
        !closingKeys.contains(state.activeTabKey)) {
      return state.activeTabKey;
    }
    if (remainingTabs.isEmpty) return null;

    final closedIndexes = <int>[];
    for (var i = 0; i < state.tabs.length; i++) {
      if (closingKeys.contains(state.tabs[i].key)) closedIndexes.add(i);
    }
    final anchorIndex = closedIndexes.isEmpty ? 0 : closedIndexes.first;

    for (var i = anchorIndex; i < state.tabs.length; i++) {
      final key = state.tabs[i].key;
      if (!closingKeys.contains(key)) return key;
    }
    return remainingTabs.last.key;
  }

  bool _isWorkTab(EditorTab tab) => tab.type != EditorTabType.connection;

  void openCreateTableTab({
    required String connectionId,
    required String database,
    String? schema,
    String? tableToEdit,
  }) {
    final key = CreateTableTabKey(
      connectionId: connectionId,
      database: database,
      schema: schema,
      tableToEdit: tableToEdit,
    );
    final index = state.tabs.indexWhere((tab) => tab.key == key);
    final tabs = List<EditorTab>.from(state.tabs);
    final tab = EditorTab(
      key: key,
      type: EditorTabType.createTable,
      title: tableToEdit != null
          ? 'Edit ${_tableTitle(tableToEdit, schema)}'
          : 'Create Table',
      connectionId: connectionId,
      database: database,
      schema: schema,
    );

    if (index == -1) {
      tabs.add(tab);
    } else {
      if (state.tabs[index] == tab && state.activeTabKey == key) return;
      tabs[index] = tab;
    }

    emit(
      EditorTabsState(
        tabs: tabs,
        activeTabKey: key,
        previewTabKey: state.previewTabKey,
      ),
    );
  }

  String _tableTitle(String tableName, String? schema) =>
      schema == null || schema.isEmpty ? tableName : '$schema.$tableName';
}
