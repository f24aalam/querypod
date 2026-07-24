import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../../core/presentation/widgets/confirmation_dialog.dart';
import '../../../editor/presentation/cubit/editor_tabs_cubit.dart';
import '../../../editor/presentation/widgets/sidebar_header.dart';
import '../cubit/connection_cubit.dart';
import '../cubit/connection_editor_cubit.dart';
import '../cubit/connection_state.dart';
import 'connection_draft_guard.dart';

class ConnectionListPanel extends StatelessWidget {
  const ConnectionListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<ConnectionCubit, ConnectionsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colors.background,
            border: Border(
              right: BorderSide(color: theme.colors.border, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SidebarHeader(
                title: 'CONNECTIONS',
                trailing: FButton(
                  variant: FButtonVariant.outline,
                  size: FButtonSizeVariant.xs,
                  mainAxisSize: MainAxisSize.min,
                  onPress: () => _openNewConnection(context),
                  child: const Text('New'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    height: 28,
                    child: TextField(
                      onChanged: (query) =>
                          context.read<ConnectionCubit>().search(query),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.foreground,
                      ),
                      cursorColor: theme.colors.primary,
                      decoration: InputDecoration(
                        hintText: 'Search connections...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: theme.colors.mutedForeground,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 16,
                          color: theme.colors.mutedForeground,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: theme.colors.secondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: theme.colors.border,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: theme.colors.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: theme.colors.primary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: state.filteredConnections
                      .map(
                        (conn) => _ConnectionItem(
                          id: conn.id,
                          name: conn.name,
                          type: conn.type.name.toUpperCase(),
                          isSelected: conn.id == state.selectedId,
                          theme: theme,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnectionItem extends StatelessWidget {
  final String id;
  final String name;
  final String type;
  final bool isSelected;
  final FThemeData theme;

  const _ConnectionItem({
    required this.id,
    required this.name,
    required this.type,
    required this.isSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final itemContext = context;
    return FContextMenu(
      menuBuilder: (context, controller, menu) => [
        FItemGroup(
          children: [
            FItem(
              title: const Text('Delete'),
              prefix: const Icon(Icons.delete_outline, size: 14),
              onPress: () {
                controller.hide();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!itemContext.mounted) return;
                  _showDeleteConfirmation(itemContext);
                });
              },
            ),
          ],
        ),
      ],
      child: GestureDetector(
        onTap: () => _openEditor(context),
        onDoubleTap: () =>
            context.read<ConnectionCubit>().openSavedConnection(id),
        child: Container(
          color: isSelected ? theme.colors.secondary : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.storage_outlined,
                size: 14,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.foreground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final editor = context.read<ConnectionEditorCubit>();
    final isSameDraft = editor.state.draft.sourceConnectionId == id;
    if (!isSameDraft && !await confirmDiscardConnectionDraft(context)) return;
    if (!context.mounted) return;

    final connection = context
        .read<ConnectionCubit>()
        .state
        .connections
        .where((connection) => connection.id == id)
        .firstOrNull;
    if (connection == null) return;

    await context.read<ConnectionCubit>().select(id);
    if (!context.mounted) return;
    final activeWorkspaceId =
        context.read<ConnectionCubit>().state.activeWorkspaceId ?? 'default';
    editor.load(connection, activeWorkspaceId: activeWorkspaceId);
    context.read<EditorTabsCubit>().openConnectionEditor(
      connectionId: id,
      connectionName: name,
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final shouldDelete = await showConfirmationDialog(
      context,
      title: 'Delete Connection',
      message: 'Are you sure you want to delete "$name"?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (!shouldDelete || !context.mounted) return;
    context.read<ConnectionCubit>().delete(id);
  }
}

Future<void> _openNewConnection(BuildContext context) async {
  final editor = context.read<ConnectionEditorCubit>();
  final isCurrentNewDraft = editor.state.isNew;
  if (!isCurrentNewDraft && !await confirmDiscardConnectionDraft(context)) {
    return;
  }
  if (!context.mounted) return;

  final activeWorkspaceId =
      context.read<ConnectionCubit>().state.activeWorkspaceId ?? 'default';
  final needsWorkspaceDraft =
      !isCurrentNewDraft || editor.state.draft.workspaceId != activeWorkspaceId;
  if (needsWorkspaceDraft) {
    editor.load(null, activeWorkspaceId: activeWorkspaceId);
  }
  await context.read<ConnectionCubit>().select(null);
  if (!context.mounted) return;
  context.read<EditorTabsCubit>().openConnectionEditor();
}
