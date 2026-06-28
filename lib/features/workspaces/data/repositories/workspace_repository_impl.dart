import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_workspace.dart';
import '../../domain/repositories/workspace_repository.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final SharedPreferences _prefs;
  static const _workspacesKey = 'querypod_workspaces';

  WorkspaceRepositoryImpl(this._prefs);

  @override
  Future<List<AppWorkspace>> getWorkspaces() async {
    final workspacesJson = _prefs.getStringList(_workspacesKey) ?? [];
    return workspacesJson
        .map((json) => AppWorkspace.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<AppWorkspace> getWorkspace(String id) async {
    final workspaces = await getWorkspaces();
    return workspaces.firstWhere((w) => w.id == id,
        orElse: () => throw Exception('Workspace not found'));
  }

  @override
  Future<AppWorkspace> createWorkspace(AppWorkspace workspace) async {
    final workspaces = await getWorkspaces();
    workspaces.add(workspace);
    await _saveWorkspaces(workspaces);
    return workspace;
  }

  @override
  Future<AppWorkspace> updateWorkspace(AppWorkspace workspace) async {
    final workspaces = await getWorkspaces();
    final index = workspaces.indexWhere((w) => w.id == workspace.id);
    if (index == -1) throw Exception('Workspace not found');
    
    workspaces[index] = workspace;
    await _saveWorkspaces(workspaces);
    return workspace;
  }

  @override
  Future<void> deleteWorkspace(String id) async {
    final workspaces = await getWorkspaces();
    workspaces.removeWhere((w) => w.id == id);
    await _saveWorkspaces(workspaces);
  }

  Future<void> _saveWorkspaces(List<AppWorkspace> workspaces) async {
    final workspacesJson =
        workspaces.map((w) => jsonEncode(w.toJson())).toList();
    await _prefs.setStringList(_workspacesKey, workspacesJson);
  }
}
