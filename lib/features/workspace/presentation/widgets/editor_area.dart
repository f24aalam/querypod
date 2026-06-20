import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/presentation/widgets/connection_form.dart';
import '../../domain/entities/workspace_table.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/editor_tabs_state.dart';

class EditorArea extends StatelessWidget {
  const EditorArea({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<EditorTabsCubit, EditorTabsState>(
      builder: (context, state) {
        return Container(
          color: theme.colors.background,
          child: Column(
            children: [
              if (state.tabs.isNotEmpty) _TabStrip(state: state),
              Expanded(child: _EditorStack(state: state)),
            ],
          ),
        );
      },
    );
  }
}

class _TabStrip extends StatelessWidget {
  final EditorTabsState state;

  const _TabStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: theme.colors.secondary,
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: state.tabs
                    .map(
                      (tab) => _EditorTabItem(
                        tab: tab,
                        isActive: tab.id == state.activeTabId,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorTabItem extends StatelessWidget {
  final EditorTab tab;
  final bool isActive;

  const _EditorTabItem({required this.tab, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final tabWidget = Material(
      color: isActive ? theme.colors.background : Colors.transparent,
      child: InkWell(
        onTap: () => context.read<EditorTabsCubit>().activate(tab.id),
        onDoubleTap: () => context.read<EditorTabsCubit>().pinTab(tab.id),
        child: Container(
          height: 34,
          width: 180,
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: theme.colors.border, width: 1),
              top: BorderSide(
                color: isActive ? theme.colors.primary : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.type == EditorTabType.connection
                    ? Icons.storage_outlined
                    : (tab.tableType == WorkspaceTableType.view
                          ? Icons.visibility_outlined
                          : Icons.table_chart_outlined),
                size: 14,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tab.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: tab.isPinned
                        ? FontStyle.normal
                        : FontStyle.italic,
                    color: theme.colors.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 12,
                  tooltip: 'Close',
                  onPressed: () =>
                      context.read<EditorTabsCubit>().closeTab(tab.id),
                  icon: Icon(
                    Icons.close,
                    size: 14,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tab.type != EditorTabType.table) return tabWidget;

    return FTooltip(
      tipBuilder: (context, controller) => Text(tab.title),
      child: tabWidget,
    );
  }
}

class _EditorStack extends StatelessWidget {
  final EditorTabsState state;

  const _EditorStack({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.tabs.isEmpty || state.activeTabId == null) {
      return const _EmptyEditor();
    }

    final activeIndex = state.tabs.indexWhere(
      (tab) => tab.id == state.activeTabId,
    );
    return IndexedStack(
      index: activeIndex < 0 ? 0 : activeIndex,
      children: state.tabs
          .map(
            (tab) => KeyedSubtree(
              key: ValueKey(tab.id),
              child: tab.type == EditorTabType.connection
                  ? const ConnectionForm()
                  : _TablePlaceholder(tab: tab),
            ),
          )
          .toList(),
    );
  }
}

class _EmptyEditor extends StatelessWidget {
  const _EmptyEditor();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: Text(
        'Open a connection or table to begin',
        style: TextStyle(fontSize: 13, color: theme.colors.mutedForeground),
      ),
    );
  }
}

class _TablePlaceholder extends StatelessWidget {
  final EditorTab tab;

  const _TablePlaceholder({required this.tab});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.tableType == WorkspaceTableType.view
                      ? Icons.visibility_outlined
                      : Icons.table_chart_outlined,
                  size: 16,
                  color: theme.colors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  tab.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tab.database ?? '',
              style: TextStyle(
                fontSize: 12,
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Table rows coming next',
              style: TextStyle(
                fontSize: 13,
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
