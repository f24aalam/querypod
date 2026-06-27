import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/connection.dart';
import 'connection_editor_state.dart';

class ConnectionEditorCubit extends Cubit<ConnectionEditorState> {
  ConnectionEditorCubit() : super(_newState());

  static ConnectionEditorState _newState() {
    final draft = ConnectionDraft.empty();
    return ConnectionEditorState(draft: draft, baseline: draft);
  }

  void load(Connection? connection) {
    final draft = connection == null
        ? ConnectionDraft.empty()
        : ConnectionDraft.fromConnection(connection);
    emit(ConnectionEditorState(draft: draft, baseline: draft));
  }

  void discard() => emit(_newState());

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
