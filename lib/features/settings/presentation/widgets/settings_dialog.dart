import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../../app/theme_cubit.dart';

void showSettingsDialog(BuildContext context) {
  showDialog(context: context, builder: (context) => const SettingsDialog());
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Dialog(
      backgroundColor: theme.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 800,
        height: 600,
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: theme.colors.secondary,
                border: Border(
                  right: BorderSide(color: theme.colors.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SidebarItem(
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Stack(
                children: [
                  if (_selectedIndex == 0)
                    const _AppearanceSettings()
                  else
                    const Center(child: Text('Placeholder')),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colors.mutedForeground,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? theme.colors.background : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? theme.colors.foreground
                      : theme.colors.mutedForeground,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected
                        ? theme.colors.foreground
                        : theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceSettings extends StatelessWidget {
  const _AppearanceSettings();

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final themeCubit = context.read<ThemeCubit>();
    final theme = context.theme;

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Text(
          'Appearance & Theme',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Theme Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ThemeMode.values.map((mode) {
                final isSelected = themeState.mode == mode;
                final label =
                    mode.name[0].toUpperCase() + mode.name.substring(1);
                final icon = switch (mode) {
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                  ThemeMode.system => Icons.desktop_windows_outlined,
                };

                final isFirst = mode == ThemeMode.values.first;
                final isLast = mode == ThemeMode.values.last;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => themeCubit.setMode(mode),
                      borderRadius: BorderRadius.horizontal(
                        left: isFirst ? const Radius.circular(7) : Radius.zero,
                        right: isLast ? const Radius.circular(7) : Radius.zero,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colors.secondary
                              : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(
                            left: isFirst
                                ? const Radius.circular(7)
                                : Radius.zero,
                            right: isLast
                                ? const Radius.circular(7)
                                : Radius.zero,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: isSelected
                                  ? theme.colors.foreground
                                  : theme.colors.mutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: isSelected
                                    ? theme.colors.foreground
                                    : theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 1,
                        height: 24,
                        color: theme.colors.border,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Color Scheme',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppColorScheme.values.map((scheme) {
            final isSelected = themeState.scheme == scheme;
            final schemeTheme = scheme.getTheme(Theme.of(context).brightness);
            final color = schemeTheme.colors.primary;

            return FTooltip(
              tipBuilder: (_, _) => Text(scheme.label),
              child: InkWell(
                onTap: () => themeCubit.setScheme(scheme),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                    border: Border.all(
                      color: isSelected
                          ? theme.colors.foreground
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: schemeTheme.colors.primaryForeground,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
