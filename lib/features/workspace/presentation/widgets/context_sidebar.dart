import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/presentation/widgets/connection_list_panel.dart';
import '../cubit/activity_cubit.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/query_editor_cubit.dart';
import '../cubit/query_editor_state.dart';
import 'history_list_panel.dart';
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
          WorkbenchActivity.history => const _HistorySidebarPanel(),
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

class _HistorySidebarPanel extends StatelessWidget {
  const _HistorySidebarPanel();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(right: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: const Column(
        children: [
          _SidebarHeader(title: 'HISTORY'),
          Expanded(
            child: HistoryListPanel(),
          ),
        ],
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
          menuBuilder: (context, controller, menu) => [
            FItemGroup(
              children: [
                FItem(
                  title: const Text('Rename'),
                  prefix: const Icon(Icons.drive_file_rename_outline, size: 14),
                  onPress: () {
                    controller.hide();
                    _showRenameDialog(context);
                  },
                ),
                FItem(
                  title: const Text('Delete'),
                  prefix: const Icon(Icons.delete_outline, size: 14),
                  variant: FItemVariant.destructive,
                  onPress: () {
                    controller.hide();
                    _showDeleteDialog(context);
                  },
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
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        direction: Axis.horizontal,
        title: const Text('Delete Query'),
        body: Text('Are you sure you want to delete "${query.title}"?'),
        actions: [
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () async {
              Navigator.of(context).pop();
              await context.read<QueryEditorCubit>().deleteQuery(query.id);
              if (!context.mounted) return;
              context.read<EditorTabsCubit>().closeQueryTab(query.id);
            },
            child: const Text('Delete'),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: query.title);

    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => StatefulBuilder(
        builder: (context, setState) {
          final trimmed = controller.text.trim();
          final isValid = trimmed.isNotEmpty && trimmed != query.title;

          return FDialog(
            animation: animation,
            direction: Axis.horizontal,
            title: const Text('Rename Query'),
            body: FTextField(
              autofocus: true,
              control: FTextFieldControl.managed(
                controller: controller,
                onChange: (_) => setState(() {}),
              ),
              hint: 'Query name',
            ),
            actions: [
              FButton(
                onPress: !isValid
                    ? null
                    : () async {
                        Navigator.of(dialogContext).pop();
                        await context.read<QueryEditorCubit>().renameQuery(
                          query.id,
                          trimmed,
                        );
                        if (!context.mounted) return;
                        context.read<EditorTabsCubit>().renameQueryTab(
                          queryId: query.id,
                          title: trimmed,
                        );
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
