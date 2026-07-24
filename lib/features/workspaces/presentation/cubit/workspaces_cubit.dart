import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/app_workspace.dart';
import '../../domain/repositories/workspace_repository.dart';
import 'workspaces_state.dart';

class WorkspacesCubit extends Cubit<WorkspacesState> {
  final WorkspaceRepository _repository;

  WorkspacesCubit({required this._repository}) : super(WorkspacesInitial());

  Future<void> loadWorkspaces() async {
    emit(WorkspacesLoading());
    try {
      final workspaces = await _repository.getWorkspaces();
      emit(WorkspacesLoaded(workspaces));
    } catch (e) {
      emit(WorkspacesError(e.toString()));
    }
  }

  Future<void> createWorkspace(String name) async {
    try {
      final now = DateTime.now();
      final workspace = AppWorkspace(
        id: const Uuid().v4(),
        name: name,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.createWorkspace(workspace);
      await loadWorkspaces();
    } catch (e) {
      emit(WorkspacesError(e.toString()));
    }
  }

  Future<void> updateWorkspace(AppWorkspace workspace) async {
    try {
      final updated = workspace.copyWith(updatedAt: DateTime.now());
      await _repository.updateWorkspace(updated);
      await loadWorkspaces();
    } catch (e) {
      emit(WorkspacesError(e.toString()));
    }
  }

  Future<void> deleteWorkspace(String id) async {
    try {
      await _repository.deleteWorkspace(id);
      await loadWorkspaces();
    } catch (e) {
      emit(WorkspacesError(e.toString()));
    }
  }
}
