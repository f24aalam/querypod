// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/workspace_query.dart';
import '../../domain/repositories/query_repository.dart';
import '../../domain/repositories/table_data_repository.dart';
import '../../../connections/domain/repositories/connection_repository.dart';
import 'query_editor_effects.dart';
import 'query_editor_state.dart';

class QueryEditorCubit extends Cubit<QueryEditorState> {
  static const _autosaveDelay = Duration(milliseconds: 400);
  static const _defaultSql =
      '-- Write your query here\nSELECT *\nFROM users\nLIMIT 100;';

  final QueryRepository _repository;
  final ConnectionRepository _connectionRepository;
  final TableDataRepository _tableDataRepository;
  final _uuid = const Uuid();
  final _effects = StreamController<QueryEditorEffect>.broadcast();
  final Map<String, Timer> _saveTimers = {};
  final Map<String, void Function()> _listeners = {};
  final Map<String, String> _lastPersistedSql = {};
  bool _isClosing = false;

  QueryEditorCubit({
    required QueryRepository repository,
    required ConnectionRepository connectionRepository,
    required TableDataRepository tableDataRepository,
  })  : _repository = repository,
        _connectionRepository = connectionRepository,
        _tableDataRepository = tableDataRepository,
        super(QueryEditorState());

  Stream<QueryEditorEffect> get effects => _effects.stream;

  Future<void> loadConnection(String? connectionId) async {
    if (state.connectionId == connectionId) return;

    await _disposeCurrentQueries(flushPending: true);

    if (connectionId == null) {
      emit(QueryEditorState(connectionId: null));
      return;
    }

    List<WorkspaceQuery> savedQueries = [];
    try {
      savedQueries = await _repository.getAllForConnection(connectionId);
    } catch (e) {
      // Ignore if database is unavailable.
    }

    final queries = savedQueries.map(_documentFromEntity).toList(growable: false);
    for (final query in queries) {
      _attachAutosave(query);
    }

    emit(QueryEditorState(connectionId: connectionId, queries: queries));
  }

  Future<QueryDocument> createQuery() async {
    final connectionId = state.connectionId;
    if (connectionId == null) {
      throw StateError('Cannot create a query without an active connection');
    }

    final title = _nextDemoTitle(state.queries.map((q) => q.title).toSet());
    final query = QueryDocument.create(
      id: _uuid.v4(),
      connectionId: connectionId,
      title: title,
      initialText: _defaultSql,
    );
    try {
      await _repository.save(_entityFromDocument(query));
    } catch (e) {
      // Ignored if database is unavailable
    }
    _attachAutosave(query);
    emit(
      QueryEditorState(
        connectionId: connectionId,
        queries: [...state.queries, query],
      ),
    );
    return query;
  }

  Future<void> renameQuery(String id, String title) async {
    final query = state.queryById(id);
    if (query == null) return;

    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed == query.title) return;

    final updated = query.copyWith(title: trimmed, updatedAt: DateTime.now());
    try {
      await _repository.save(_entityFromDocument(updated));
    } catch (e) {
      // Ignored if database is unavailable
    }
    emit(
      QueryEditorState(
        connectionId: state.connectionId,
        queries: _replaceQuery(updated),
      ),
    );
    _effects.add(QueryRenamed(queryId: id, title: trimmed));
  }

  Future<void> deleteQuery(String id) async {
    final query = state.queryById(id);
    if (query == null) return;

    _cancelAutosave(id);
    _detachAutosave(id, query);
    try {
      await _repository.delete(id);
    } catch (e) {
      // Ignored if the database file is unavailable.
    }
    query.dispose();
    emit(
      QueryEditorState(
        connectionId: state.connectionId,
        queries: state.queries.where((query) => query.id != id).toList(),
      ),
    );
    _effects.add(QueryDeleted(queryId: id));
  }

  Future<void> runQuery(String queryId) async {
    final query = state.queryById(queryId);
    final connectionId = state.connectionId;
    if (query == null || connectionId == null) return;

    var sql = '';
    final selection = query.controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      sql = selection.textInside(query.controller.text);
    }
    if (sql.trim().isEmpty) sql = query.controller.text;
    if (sql.trim().isEmpty) return;

    emit(
      QueryEditorState(
        connectionId: connectionId,
        queries: _replaceQuery(query.copyWith(isRunning: true)),
      ),
    );

    final connection = await _connectionRepository.getById(connectionId);
    if (connection == null) {
      final updatedQuery = state.queryById(queryId);
      if (updatedQuery != null) {
        emit(
          QueryEditorState(
            connectionId: connectionId,
            queries: _replaceQuery(updatedQuery.copyWith(isRunning: false)),
          ),
        );
      }
      return;
    }

    final results = await _tableDataRepository.executeQuery(
      connection,
      connection.database,
      sql,
    );

    for (final result in results) {
      if (result.errorMessage != null) {
        _effects.add(QueryExecutionError(errorMessage: result.errorMessage!));
      }
    }

    final updatedQuery = state.queryById(queryId);
    if (updatedQuery != null) {
      emit(
        QueryEditorState(
          connectionId: connectionId,
          queries: _replaceQuery(
            updatedQuery.copyWith(isRunning: false, results: results),
          ),
        ),
      );
    }
  }

  QueryDocument? queryById(String id) => state.queryById(id);

  Future<void> flushPendingSaves() async {
    for (final query in state.queries) {
      await _flushQuery(query.id);
    }
  }

  @override
  Future<void> close() async {
    _isClosing = true;
    await _disposeCurrentQueries(flushPending: true);
    await _effects.close();
    return super.close();
  }

  List<QueryDocument> _replaceQuery(QueryDocument updated) {
    return [
      for (final query in state.queries)
        query.id == updated.id ? updated : query,
    ];
  }

  QueryDocument _documentFromEntity(WorkspaceQuery query) {
    return QueryDocument.bootstrap(
      id: query.id,
      connectionId: query.connectionId,
      title: query.title,
      sql: query.sql,
      createdAt: query.createdAt,
      updatedAt: query.updatedAt,
    );
  }

  WorkspaceQuery _entityFromDocument(QueryDocument query) {
    return WorkspaceQuery(
      id: query.id,
      connectionId: query.connectionId,
      title: query.title,
      sql: query.controller.fullText,
      createdAt: query.createdAt,
      updatedAt: query.updatedAt,
    );
  }

  void _attachAutosave(QueryDocument query) {
    _lastPersistedSql[query.id] = query.controller.fullText;
    void listener() {
      if (_isClosing) return;
      if (query.controller.fullText == _lastPersistedSql[query.id]) return;
      _scheduleSave(query.id);
    }

    _listeners[query.id] = listener;
    query.controller.addListener(listener);
  }

  void _detachAutosave(String id, QueryDocument query) {
    final listener = _listeners.remove(id);
    if (listener != null) {
      query.controller.removeListener(listener);
    }
    _lastPersistedSql.remove(id);
  }

  void _scheduleSave(String queryId) {
    _cancelAutosave(queryId);
    _saveTimers[queryId] = Timer(
      _autosaveDelay,
      () => unawaited(_flushQuery(queryId)),
    );
  }

  void _cancelAutosave(String queryId) {
    _saveTimers.remove(queryId)?.cancel();
  }

  Future<void> _flushQuery(String queryId) async {
    _cancelAutosave(queryId);
    final query = state.queryById(queryId);
    if (query == null) return;

    final updated = query.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.save(_entityFromDocument(updated));
      _lastPersistedSql[queryId] = updated.controller.fullText;
      if (_isClosing || isClosed) return;
      emit(
        QueryEditorState(
          connectionId: state.connectionId,
          queries: _replaceQuery(updated),
        ),
      );
    } catch (e) {
      // Silently fail if we can't save the query (e.g. database file deleted)
      // The user can continue working but changes won't be persisted.
    }
  }

  Future<void> _disposeCurrentQueries({required bool flushPending}) async {
    for (final query in state.queries) {
      if (flushPending) {
        await _flushQuery(query.id);
      } else {
        _cancelAutosave(query.id);
      }
      _detachAutosave(query.id, query);
      query.dispose();
    }
  }

  String _nextDemoTitle(Set<String> existingTitles) {
    var index = 1;
    while (true) {
      final candidate = index == 1 ? 'demo' : 'demo $index';
      if (!existingTitles.contains(candidate)) return candidate;
      index += 1;
    }
  }
}
