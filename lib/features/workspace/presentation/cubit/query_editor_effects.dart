sealed class QueryEditorEffect {
  const QueryEditorEffect();
}

class QueryRenamed extends QueryEditorEffect {
  final String queryId;
  final String title;

  const QueryRenamed({required this.queryId, required this.title});
}

class QueryDeleted extends QueryEditorEffect {
  final String queryId;

  const QueryDeleted({required this.queryId});
}

class QueryExecutionError extends QueryEditorEffect {
  final String errorMessage;

  const QueryExecutionError({required this.errorMessage});
}
