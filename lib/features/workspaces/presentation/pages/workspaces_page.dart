import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/confirmation_dialog.dart';
import '../cubit/workspaces_cubit.dart';
import '../cubit/workspaces_state.dart';
import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../../editor/presentation/widgets/app_title_bar.dart';
import '../../domain/entities/app_workspace.dart';

class WorkspacesPage extends StatefulWidget {
  const WorkspacesPage({super.key});

  @override
  State<WorkspacesPage> createState() => _WorkspacesPageState();
}

class _WorkspacesPageState extends State<WorkspacesPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkspacesCubit>().loadWorkspaces();
  }

  Future<void> _showDeleteDialog(AppWorkspace workspace) async {
    final shouldDelete = await showConfirmationDialog(
      context,
      title: 'Delete Workspace',
      message: 'Are you sure you want to delete "${workspace.name}"?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (!shouldDelete || !mounted) return;
    context.read<WorkspacesCubit>().deleteWorkspace(workspace.id);
  }

  void _showRenameDialog(AppWorkspace workspace) {
    final controller = TextEditingController(text: workspace.name);

    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => StatefulBuilder(
        builder: (context, setState) {
          final trimmed = controller.text.trim();
          final isValid = trimmed.isNotEmpty && trimmed != workspace.name;

          return FDialog(
            animation: animation,
            direction: Axis.horizontal,
            title: const Text('Rename Workspace'),
            body: FTextField(
              autofocus: true,
              control: FTextFieldControl.managed(
                controller: controller,
                onChange: (_) => setState(() {}),
              ),
              hint: 'Workspace name',
            ),
            actions: [
              FButton(
                onPress: !isValid
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        final updated = workspace.copyWith(name: trimmed);
                        this.context.read<WorkspacesCubit>().updateWorkspace(updated);
                      },
                child: const Text('Rename'),
              ),
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => const _CreateWorkspaceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.colors.background,
      body: Column(
          children: [
            const AppTitleBar(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 80),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workspaces',
                    style: TextStyle(fontSize: 24).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FButton(
                    onPress: _showCreateDialog,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 8),
                        Text('Create Workspace'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Group your database connections by project or environment.',
                style: TextStyle(fontSize: 16).copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: BlocBuilder<WorkspacesCubit, WorkspacesState>(
                  builder: (context, state) {
                    if (state is WorkspacesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is WorkspacesError) {
                      return Center(
                        child: Text(
                          'Error: ${state.message}',
                          style: TextStyle(color: context.theme.colors.destructive),
                        ),
                      );
                    } else if (state is WorkspacesLoaded) {
                      if (state.workspaces.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 64,
                                color: context.theme.colors.mutedForeground,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No workspaces yet',
                                style: TextStyle(fontSize: 18).copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a workspace to start adding connections.',
                                style: TextStyle(fontSize: 14).copyWith(
                                  color: context.theme.colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FButton(
                                onPress: _showCreateDialog,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.add, size: 16),
                                    SizedBox(width: 8),
                                    Text('Create your first workspace'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: state.workspaces.length,
                        itemBuilder: (context, index) {
                          final workspace = state.workspaces[index];
                          return Material(
                            color: context.theme.colors.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: context.theme.colors.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                context.read<ConnectionCubit>().setWorkspace(workspace.id);
                                context.go('/workspace/${workspace.id}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: context.theme.colors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.workspaces_outline,
                                            color: context.theme.colors.primary,
                                            size: 24,
                                          ),
                                        ),
                                        const Spacer(),
                                        FPopoverMenu(
                                          menuBuilder: (context, controller, menu) => [
                                            FItemGroup(
                                              children: [
                                                FItem(
                                                  title: const Text('Rename'),
                                                  prefix: const Icon(Icons.drive_file_rename_outline, size: 14),
                                                  onPress: () {
                                                    controller.hide();
                                                    _showRenameDialog(workspace);
                                                  },
                                                ),
                                                FItem(
                                                  title: const Text('Delete'),
                                                  prefix: const Icon(Icons.delete_outline, size: 14),
                                                  variant: FItemVariant.destructive,
                                                  onPress: () {
                                                    controller.hide();
                                                    _showDeleteDialog(workspace);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                          builder: (context, controller, child) => IconButton(
                                            icon: Icon(
                                              Icons.more_horiz,
                                              color: context.theme.colors.mutedForeground,
                                            ),
                                            onPressed: () => controller.toggle(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      workspace.name,
                                      style: TextStyle(fontSize: 18).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Created ${DateFormat.yMMMd().format(workspace.createdAt)}',
                                      style: TextStyle(fontSize: 12).copyWith(
                                        color: context.theme.colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
            ), // closes Expanded
          ], // closes outer Column children
        ), // closes outer Column
    ); // closes Scaffold
  }
}

class _CreateWorkspaceDialog extends StatefulWidget {
  const _CreateWorkspaceDialog();

  @override
  State<_CreateWorkspaceDialog> createState() => _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends State<_CreateWorkspaceDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      context.read<WorkspacesCubit>().createWorkspace(name);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.theme.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.theme.colors.border, width: 1),
      ),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Workspace',
                style: TextStyle(fontSize: 18).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a name for your new workspace.',
                style: TextStyle(fontSize: 14).copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              FTextField(
                control: FTextFieldControl.managed(
                  controller: _nameController,
                  onChange: (value) {},
                ),
                label: const Text('Workspace Name'),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FButton(
                    onPress: _submit,
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
