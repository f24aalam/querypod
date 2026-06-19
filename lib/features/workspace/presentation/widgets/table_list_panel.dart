import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class TableListPanel extends StatelessWidget {
  const TableListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(right: BorderSide(color: theme.colors.border, width: 1)),
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
                'TABLES',
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
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.foreground,
                  ),
                  cursorColor: theme.colors.primary,
                  decoration: InputDecoration(
                    hintText: 'Search tables...',
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
              children: [
                _TableItem(
                  icon: Icons.table_chart_outlined,
                  name: 'users',
                  theme: theme,
                ),
                _TableItem(
                  icon: Icons.table_chart_outlined,
                  name: 'orders',
                  theme: theme,
                ),
                _TableItem(
                  icon: Icons.table_chart_outlined,
                  name: 'products',
                  theme: theme,
                ),
                _TableItem(
                  icon: Icons.table_chart_outlined,
                  name: 'categories',
                  theme: theme,
                ),
                _TableItem(
                  icon: Icons.visibility_outlined,
                  name: 'order_summary',
                  theme: theme,
                  isView: true,
                ),
                _TableItem(
                  icon: Icons.visibility_outlined,
                  name: 'user_stats',
                  theme: theme,
                  isView: true,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colors.border, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Material(
              color: Colors.transparent,
              child: FPopoverMenu(
                menu: [
                  FItemGroup(
                    children: [
                      FItem(
                        prefix: const Icon(
                          Icons.table_chart_outlined,
                          size: 14,
                        ),
                        title: const Text('users'),
                        onPress: () {},
                      ),
                      FItem(
                        prefix: const Icon(
                          Icons.table_chart_outlined,
                          size: 14,
                        ),
                        title: const Text('orders'),
                        onPress: () {},
                      ),
                      FItem(
                        prefix: const Icon(
                          Icons.table_chart_outlined,
                          size: 14,
                        ),
                        title: const Text('products'),
                        onPress: () {},
                      ),
                      FItem(
                        prefix: const Icon(
                          Icons.table_chart_outlined,
                          size: 14,
                        ),
                        title: const Text('categories'),
                        onPress: () {},
                      ),
                      FItem(
                        prefix: const Icon(Icons.visibility_outlined, size: 14),
                        title: const Text('order_summary'),
                        onPress: () {},
                      ),
                      FItem(
                        prefix: const Icon(Icons.visibility_outlined, size: 14),
                        title: const Text('user_stats'),
                        onPress: () {},
                      ),
                    ],
                  ),
                ],
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.colors.secondary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 14,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'users',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colors.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: theme.colors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final FThemeData theme;
  final bool isView;

  const _TableItem({
    required this.icon,
    required this.name,
    required this.theme,
    this.isView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 13, color: theme.colors.foreground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
