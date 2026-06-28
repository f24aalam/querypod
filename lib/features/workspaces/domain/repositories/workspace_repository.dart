import '../entities/app_workspace.dart';

abstract class WorkspaceRepository {
  Future<List<AppWorkspace>> getWorkspaces();
  Future<AppWorkspace> getWorkspace(String id);
  Future<AppWorkspace> createWorkspace(AppWorkspace workspace);
  Future<AppWorkspace> updateWorkspace(AppWorkspace workspace);
  Future<void> deleteWorkspace(String id);
}
