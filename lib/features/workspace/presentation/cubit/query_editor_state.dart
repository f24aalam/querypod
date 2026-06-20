import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/sql.dart' as highlight;

class QueryDocument {
  final String id;
  final String connectionId;
  final String title;
  final CodeController controller;
  final DateTime createdAt;
  final DateTime updatedAt;

  QueryDocument({
    required this.id,
    required this.connectionId,
    required this.title,
    required this.controller,
    required this.createdAt,
    required this.updatedAt,
  });

  QueryDocument copyWith({
    String? title,
    String? connectionId,
    DateTime? updatedAt,
    CodeController? controller,
  }) {
    return QueryDocument(
      id: id,
      connectionId: connectionId ?? this.connectionId,
      title: title ?? this.title,
      controller: controller ?? this.controller,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory QueryDocument.bootstrap({
    required String id,
    required String connectionId,
    required String title,
    required String sql,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return QueryDocument(
      id: id,
      connectionId: connectionId,
      title: title,
      controller: CodeController(text: sql, language: highlight.sql),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory QueryDocument.create({
    required String id,
    required String connectionId,
    required String title,
    String initialText =
        '-- Write your query here\nSELECT *\nFROM users\nLIMIT 100;',
  }) {
    final now = DateTime.now();
    return QueryDocument(
      id: id,
      connectionId: connectionId,
      title: title,
      controller: CodeController(text: initialText, language: highlight.sql),
      createdAt: now,
      updatedAt: now,
    );
  }

  void dispose() {
    controller.dispose();
  }
}

class QueryEditorState {
  final String? connectionId;
  final List<QueryDocument> queries;

  QueryEditorState({this.connectionId, List<QueryDocument> queries = const []})
    : queries = List.unmodifiable(queries);

  QueryDocument? queryById(String id) {
    for (final query in queries) {
      if (query.id == id) return query;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryEditorState &&
          connectionId == other.connectionId &&
          _listEquals(queries, other.queries);

  @override
  int get hashCode => Object.hash(connectionId, Object.hashAll(queries));
}

bool _listEquals(List<QueryDocument> a, List<QueryDocument> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final left = a[i];
    final right = b[i];
    if (left.id != right.id || left.title != right.title) return false;
  }
  return true;
}
