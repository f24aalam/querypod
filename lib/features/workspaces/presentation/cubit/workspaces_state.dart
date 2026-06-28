import 'package:equatable/equatable.dart';

import '../../domain/entities/app_workspace.dart';

abstract class WorkspacesState extends Equatable {
  const WorkspacesState();

  @override
  List<Object?> get props => [];
}

class WorkspacesInitial extends WorkspacesState {}

class WorkspacesLoading extends WorkspacesState {}

class WorkspacesLoaded extends WorkspacesState {
  final List<AppWorkspace> workspaces;

  const WorkspacesLoaded(this.workspaces);

  @override
  List<Object?> get props => [workspaces];
}

class WorkspacesError extends WorkspacesState {
  final String message;

  const WorkspacesError(this.message);

  @override
  List<Object?> get props => [message];
}
