import '../../domain/entities/workspace_table.dart';

enum EditorTabType { connection, table, query, createTable }

sealed class EditorTabKey {
  const EditorTabKey();
}

class ConnectionEditorTabKey extends EditorTabKey {
  const ConnectionEditorTabKey();

  @override
  bool operator ==(Object other) => other is ConnectionEditorTabKey;

  @override
  int get hashCode => 0x434f4e4e;
}

class CreateTableTabKey extends EditorTabKey {
  final String connectionId;
  final String database;

  const CreateTableTabKey({
    required this.connectionId,
    required this.database,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateTableTabKey &&
          connectionId == other.connectionId &&
          database == other.database;

  @override
  int get hashCode => Object.hash(connectionId, database);
}


class TableTabKey extends EditorTabKey {
  final String connectionId;
  final String database;
  final String tableName;

  const TableTabKey({
    required this.connectionId,
    required this.database,
    required this.tableName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableTabKey &&
          connectionId == other.connectionId &&
          database == other.database &&
          tableName == other.tableName;

  @override
  int get hashCode => Object.hash(connectionId, database, tableName);
}

class QueryTabKey extends EditorTabKey {
  final String queryId;

  const QueryTabKey({required this.queryId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryTabKey && queryId == other.queryId;

  @override
  int get hashCode => queryId.hashCode;
}

class EditorTab {
  final EditorTabKey key;
  final EditorTabType type;
  final String title;
  final String? connectionId;
  final String? database;
  final WorkspaceTableType? tableType;
  final bool isPinned;

  const EditorTab({
    required this.key,
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
      key: key,
      type: type,
      title: title ?? this.title,
      connectionId: connectionId != null ? connectionId() : this.connectionId,
      database: database,
      tableType: tableType,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorTab &&
          key == other.key &&
          type == other.type &&
          title == other.title &&
          connectionId == other.connectionId &&
          database == other.database &&
          tableType == other.tableType &&
          isPinned == other.isPinned;

  @override
  int get hashCode => Object.hash(
    key,
    type,
    title,
    connectionId,
    database,
    tableType,
    isPinned,
  );
}

class EditorTabsState {
  final List<EditorTab> tabs;
  final EditorTabKey? activeTabKey;
  final EditorTabKey? previewTabKey;

  EditorTabsState({
    List<EditorTab> tabs = const [],
    this.activeTabKey,
    this.previewTabKey,
  }) : tabs = List.unmodifiable(tabs);

  EditorTab? get activeTab {
    for (final tab in tabs) {
      if (tab.key == activeTabKey) return tab;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorTabsState &&
          activeTabKey == other.activeTabKey &&
          previewTabKey == other.previewTabKey &&
          _listEquals(tabs, other.tabs);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(tabs), activeTabKey, previewTabKey);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
