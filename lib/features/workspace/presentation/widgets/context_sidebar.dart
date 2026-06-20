import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/presentation/widgets/connection_list_panel.dart';
import '../cubit/activity_cubit.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/query_editor_cubit.dart';
import '../cubit/query_editor_state.dart';
import 'table_list_panel.dart';

class ContextSidebar extends StatelessWidget {
  const ContextSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityCubit, WorkbenchActivity>(
      builder: (context, activity) {
        return switch (activity) {
          WorkbenchActivity.connections => const ConnectionListPanel(),
          WorkbenchActivity.tables => const TableListPanel(),
          WorkbenchActivity.history => const _SidebarPlaceholder(
            title: 'HISTORY',
            message: 'Query history coming soon',
          ),
          WorkbenchActivity.query => const _QuerySidebarPanel(),
          WorkbenchActivity.settings => const _SidebarPlaceholder(
            title: 'SETTINGS',
            message: 'Settings coming soon',
          ),
        };
      },
    );
  }
}

class _QuerySidebarPanel extends StatelessWidget {
  const _QuerySidebarPanel();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(right: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: BlocBuilder<QueryEditorCubit, QueryEditorState>(
        builder: (context, state) => Column(
          children: [
            _SidebarHeader(
              title: 'QUERY',
              trailing: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 14,
                tooltip: 'New query',
                onPressed: () async {
                  final query = await context
                      .read<QueryEditorCubit>()
                      .createQuery();
                  if (!context.mounted) return;
                  context.read<EditorTabsCubit>().openQuery(
                    queryId: query.id,
                    title: query.title,
                  );
                },
                icon: Icon(
                  Icons.add,
                  size: 16,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
            Expanded(
              child: state.queries.isEmpty
                  ? Center(
                      child: Text(
                        'Create a query from +',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: state.queries.length,
                      itemBuilder: (context, index) =>
                          _QueryListItem(query: state.queries[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueryListItem extends StatelessWidget {
  final QueryDocument query;

  const _QueryListItem({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocSelector<EditorTabsCubit, EditorTabsState, bool>(
      selector: (state) => state.activeTabKey == QueryTabKey(queryId: query.id),
      builder: (context, isActive) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: FContextMenu(
          menu: [
            FItemGroup(
              children: [
                FItem(
                  title: const Text('Rename'),
                  prefix: const Icon(Icons.drive_file_rename_outline, size: 14),
                  onPress: () => _showRenameDialog(context),
                ),
                FItem(
                  title: const Text('Delete'),
                  prefix: const Icon(Icons.delete_outline, size: 14),
                  variant: FItemVariant.destructive,
                  onPress: () => _showDeleteDialog(context),
                ),
              ],
            ),
          ],
          child: Material(
            color: isActive ? theme.colors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => context.read<EditorTabsCubit>().openQuery(
                queryId: query.id,
                title: query.title,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: isActive
                          ? theme.colors.foreground
                          : theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        query.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: theme.colors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final theme = context.theme;
    showFDialog(
      context: context,
      builder: (context, style, animation) => Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Query',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "${query.title}"?',
              style: TextStyle(fontSize: 14, color: theme.colors.foreground),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FButton(
                  variant: FButtonVariant.destructive,
                  onPress: () async {
                    Navigator.of(context).pop();
                    await context.read<QueryEditorCubit>().deleteQuery(
                      query.id,
                    );
                    if (!context.mounted) return;
                    context.read<EditorTabsCubit>().closeQueryTab(query.id);
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final theme = context.theme;
    final controller = TextEditingController(text: query.title);

    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => StatefulBuilder(
        builder: (context, setState) {
          final trimmed = controller.text.trim();
          final isValid = trimmed.isNotEmpty && trimmed != query.title;

          return Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rename Query',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colors.foreground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Query name',
                      filled: true,
                      fillColor: theme.colors.secondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: theme.colors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: theme.colors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: theme.colors.primary,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      onPress: !isValid
                          ? null
                          : () async {
                              Navigator.of(dialogContext).pop();
                              await context
                                  .read<QueryEditorCubit>()
                                  .renameQuery(query.id, trimmed);
                              if (!context.mounted) return;
                              context.read<EditorTabsCubit>().renameQueryTab(
                                queryId: query.id,
                                title: trimmed,
                              );
                            },
                      child: const Text('Rename'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }
}

class _SidebarPlaceholder extends StatelessWidget {
  final String title;
  final String message;

  const _SidebarPlaceholder({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(right: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Column(
        children: [
          _SidebarHeader(title: title),
          Expanded(
            child: Center(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SidebarHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
          if (trailing != null) ...[trailing!],
        ],
      ),
    );
  }
}
