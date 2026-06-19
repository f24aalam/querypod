import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../cubit/connection_cubit.dart';
import '../cubit/connection_state.dart';

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
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.colors.border, width: 1),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CONNECTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
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
                          host: conn.host,
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
  final String host;
  final bool isSelected;
  final FThemeData theme;

  const _ConnectionItem({
    required this.id,
    required this.name,
    required this.host,
    required this.isSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return FContextMenu(
      menu: [
        FItemGroup(
          children: [
            FItem(
              title: const Text('Delete'),
              prefix: const Icon(Icons.delete_outline, size: 14),
              onPress: () => _showDeleteConfirmation(context),
            ),
          ],
        ),
      ],
      child: GestureDetector(
        onTap: () => context.read<ConnectionCubit>().select(id),
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
                      host,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colors.mutedForeground,
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

  void _showDeleteConfirmation(BuildContext context) {
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
              'Delete Connection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "$name"?',
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
                  onPress: () {
                    Navigator.of(context).pop();
                    context.read<ConnectionCubit>().delete(id);
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
}
