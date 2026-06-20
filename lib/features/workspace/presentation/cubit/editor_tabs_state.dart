import '../../domain/entities/workspace_table.dart';

enum EditorTabType { connection, table }

class EditorTab {
  final String id;
  final EditorTabType type;
  final String title;
  final String? connectionId;
  final String? database;
  final WorkspaceTableType? tableType;
  final bool isPinned;

  const EditorTab({
    required this.id,
    required this.type,
    required this.title,
    this.connectionId,
    this.database,
    this.tableType,
    this.isPinned = true,
  });

  EditorTab copyWith({
    String? title,
    String? Function()? connectionId,
    bool? isPinned,
  }) {
    return EditorTab(
      id: id,
      type: type,
      title: title ?? this.title,
      connectionId: connectionId != null ? connectionId() : this.connectionId,
      database: database,
      tableType: tableType,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

class EditorTabsState {
  final List<EditorTab> tabs;
  final String? activeTabId;
  final String? previewTabId;

  const EditorTabsState({
    this.tabs = const [],
    this.activeTabId,
    this.previewTabId,
  });

  EditorTab? get activeTab {
    for (final tab in tabs) {
      if (tab.id == activeTabId) return tab;
    }
    return null;
  }
}
