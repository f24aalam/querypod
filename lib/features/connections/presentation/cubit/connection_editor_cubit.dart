import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/connection.dart';
import 'connection_editor_state.dart';

class ConnectionEditorCubit extends Cubit<ConnectionEditorState> {
  ConnectionEditorCubit()
      : super(ConnectionEditorState(
          draft: ConnectionDraft.empty('default'),
          baseline: ConnectionDraft.empty('default'),
        ));

  void load(Connection? connection, {required String activeWorkspaceId}) {
    final draft = connection == null
        ? ConnectionDraft.empty(activeWorkspaceId)
        : ConnectionDraft.fromConnection(connection);
    emit(ConnectionEditorState(draft: draft, baseline: draft));
  }

  void discard(String workspaceId) {
    final draft = ConnectionDraft.empty(workspaceId);
    emit(ConnectionEditorState(draft: draft, baseline: draft));
  }

  void markSaved(Connection connection) {
    final draft = ConnectionDraft.fromConnection(connection);
    emit(ConnectionEditorState(draft: draft, baseline: draft));
  }

  void updateName(String value) => _update(state.draft.copyWith(name: value));
  void updateHost(String value) => _update(state.draft.copyWith(host: value));
  void updatePort(String value) => _update(state.draft.copyWith(port: value));
  void updateUser(String value) => _update(state.draft.copyWith(user: value));
  void updatePassword(String value) =>
      _update(state.draft.copyWith(password: value));
  void updateDatabase(String value) =>
      _update(state.draft.copyWith(database: value));
  void updateType(ConnectionType value) =>
      _update(state.draft.copyWith(type: value));
  void updateUseTls(bool value) =>
      _update(state.draft.copyWith(useTls: value));

  void _update(ConnectionDraft draft) {
    if (draft == state.draft) return;
    emit(ConnectionEditorState(draft: draft, baseline: state.baseline));
  }
}
