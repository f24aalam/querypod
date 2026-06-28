import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/sql.dart' as highlight;

import '../../domain/entities/query_result.dart';

class QueryDocument {
  final String id;
  final String connectionId;
  final String title;
  final String? database;
  final CodeController controller;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRunning;
  final List<QueryResult>? results;

  QueryDocument({
    required this.id,
    required this.connectionId,
    required this.title,
    this.database,
    required this.controller,
    required this.createdAt,
    required this.updatedAt,
    this.isRunning = false,
    this.results,
  });

  QueryDocument copyWith({
    String? title,
    String? connectionId,
    String? Function()? database,
    DateTime? updatedAt,
    CodeController? controller,
    bool? isRunning,
    List<QueryResult>? results,
  }) {
    return QueryDocument(
      id: id,
      connectionId: connectionId ?? this.connectionId,
      title: title ?? this.title,
      database: database != null ? database() : this.database,
      controller: controller ?? this.controller,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRunning: isRunning ?? this.isRunning,
      results: results ?? this.results,
    );
  }

  factory QueryDocument.bootstrap({
    required String id,
    required String connectionId,
    required String title,
    required String sql,
    String? database,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return QueryDocument(
      id: id,
      connectionId: connectionId,
      title: title,
      database: database,
      controller: CodeController(text: sql, language: highlight.sql),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory QueryDocument.create({
    required String id,
    required String connectionId,
    required String title,
    String? database,
    String initialText =
        '-- Write your query here\nSELECT *\nFROM users\nLIMIT 100;',
  }) {
    final now = DateTime.now();
    return QueryDocument(
      id: id,
      connectionId: connectionId,
      title: title,
      database: database,
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
    if (left.id != right.id ||
        left.title != right.title ||
        left.database != right.database ||
        left.isRunning != right.isRunning ||
        !identical(left.results, right.results)) {
      return false;
    }
  }
  return true;
}
