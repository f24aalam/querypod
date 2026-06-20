import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/presentation/cubit/connection_editor_cubit.dart';
import '../../../connections/presentation/widgets/connection_draft_guard.dart';
import '../../../connections/presentation/widgets/connection_form.dart';
import '../../domain/entities/workspace_table.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/query_editor_cubit.dart';
import 'query_code_editor.dart';
import 'table_data_editor.dart';

class EditorArea extends StatelessWidget {
  const EditorArea({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      color: theme.colors.background,
      child: const Column(
        children: [
          _TabStrip(),
          Expanded(child: _ActiveEditor()),
        ],
      ),
    );
  }
}

class _TabStrip extends StatefulWidget {
  const _TabStrip();

  @override
  State<_TabStrip> createState() => _TabStripState();
}

class _TabStripState extends State<_TabStrip> {
  static const _tabWidth = 180.0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureActiveTabVisible(EditorTabsState state) {
    final activeKey = state.activeTabKey;
    if (activeKey == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final index = state.tabs.indexWhere((tab) => tab.key == activeKey);
      if (index < 0) return;
      final position = _scrollController.position;
      final start = index * _tabWidth;
      final end = start + _tabWidth;
      final visibleStart = position.pixels;
      final visibleEnd = visibleStart + position.viewportDimension;
      final target = start < visibleStart
          ? start
          : (end > visibleEnd ? end - position.viewportDimension : null);
      if (target == null) return;
      _scrollController.animateTo(
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocListener<EditorTabsCubit, EditorTabsState>(
      listenWhen: (previous, current) =>
          previous.activeTabKey != current.activeTabKey,
      listener: (context, state) => _ensureActiveTabVisible(state),
      child: BlocSelector<EditorTabsCubit, EditorTabsState, _TabStripLayout>(
        selector: (state) =>
            _TabStripLayout(state.tabs.map((tab) => tab.key).toList()),
        builder: (context, layout) {
          if (layout.keys.isEmpty) return const SizedBox.shrink();

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
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: layout.keys
                          .map((key) => _EditorTabItem(tabKey: key))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabStripLayout {
  final List<EditorTabKey> keys;

  _TabStripLayout(List<EditorTabKey> keys) : keys = List.unmodifiable(keys);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _TabStripLayout || keys.length != other.keys.length) {
      return false;
    }
    for (var i = 0; i < keys.length; i++) {
      if (keys[i] != other.keys[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(keys);
}

class _TabItemView {
  final EditorTab tab;
  final bool isActive;

  const _TabItemView({required this.tab, required this.isActive});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TabItemView && tab == other.tab && isActive == other.isActive;

  @override
  int get hashCode => Object.hash(tab, isActive);
}

class _EditorTabItem extends StatelessWidget {
  final EditorTabKey tabKey;

  const _EditorTabItem({required this.tabKey});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<EditorTabsCubit, EditorTabsState, _TabItemView?>(
      selector: (state) {
        final matches = state.tabs.where((tab) => tab.key == tabKey);
        if (matches.isEmpty) return null;
        return _TabItemView(
          tab: matches.first,
          isActive: state.activeTabKey == tabKey,
        );
      },
      builder: (context, view) {
        if (view == null) return const SizedBox.shrink();
        return _EditorTabBody(
          tab: view.tab,
          isActive: view.isActive,
          onClose: () => _closeTab(context, view.tab),
        );
      },
    );
  }

  Future<void> _closeTab(BuildContext context, EditorTab tab) async {
    if (tab.type == EditorTabType.connection) {
      if (!await confirmDiscardConnectionDraft(context)) return;
      if (!context.mounted) return;
      context.read<ConnectionEditorCubit>().discard();
    }
    if (!context.mounted) return;
    context.read<EditorTabsCubit>().closeTab(tab.key);
  }
}

class _EditorTabBody extends StatelessWidget {
  final EditorTab tab;
  final bool isActive;
  final VoidCallback onClose;

  const _EditorTabBody({
    required this.tab,
    required this.isActive,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Material(
      key: ValueKey<(String, EditorTabKey)>(('tab-strip', tab.key)),
      color: isActive ? theme.colors.background : Colors.transparent,
      child: Container(
        height: 34,
        width: 180,
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
          children: [
            Expanded(
              child: InkWell(
                onTapDown: (_) =>
                    context.read<EditorTabsCubit>().activate(tab.key),
                onDoubleTap: () =>
                    context.read<EditorTabsCubit>().pinTab(tab.key),
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        Icon(
                          tab.type == EditorTabType.connection
                              ? Icons.storage_outlined
                              : tab.type == EditorTabType.query
                              ? Icons.code_outlined
                              : (tab.tableType == WorkspaceTableType.view
                                    ? Icons.visibility_outlined
                                    : Icons.table_chart_outlined),
                          size: 14,
                          color: theme.colors.mutedForeground,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: tab.type != EditorTabType.connection
                              ? FTooltip(
                                  tipBuilder: (context, controller) =>
                                      Text(tab.title),
                                  child: _TabTitle(tab: tab, theme: theme),
                                )
                              : _TabTitle(tab: tab, theme: theme),
                        ),
                      ],
                    ),
                  ),
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
                onPressed: onClose,
                icon: Icon(
                  Icons.close,
                  size: 14,
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _TabTitle extends StatelessWidget {
  final EditorTab tab;
  final FThemeData theme;

  const _TabTitle({required this.tab, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      tab.title,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontStyle: tab.isPinned ? FontStyle.normal : FontStyle.italic,
        color: theme.colors.foreground,
      ),
    );
  }
}

class _ActiveEditor extends StatelessWidget {
  const _ActiveEditor();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<EditorTabsCubit, EditorTabsState, EditorTab?>(
      selector: (state) => state.activeTab,
      builder: (context, tab) {
        if (tab == null) return const _EmptyEditor();
        return KeyedSubtree(
          key: ValueKey(tab.key),
          child: tab.type == EditorTabType.connection
              ? const ConnectionForm()
              : tab.type == EditorTabType.table
              ? TableDataEditor(tab: tab)
              : _QueryEditorTab(tab: tab),
        );
      },
    );
  }
}

class _QueryEditorTab extends StatelessWidget {
  final EditorTab tab;

  const _QueryEditorTab({required this.tab});

  @override
  Widget build(BuildContext context) {
    final key = tab.key as QueryTabKey;
    final query = context.select(
      (QueryEditorCubit cubit) => cubit.state.queryById(key.queryId),
    );

    if (query == null) {
      return const Center(child: Text('Query not found'));
    }

    return QueryCodeEditor(controller: query.controller);
  }
}

class _EmptyEditor extends StatelessWidget {
  const _EmptyEditor();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: Text(
        'Open a connection, table, or query to begin',
        style: TextStyle(fontSize: 13, color: theme.colors.mutedForeground),
      ),
    );
  }
}
