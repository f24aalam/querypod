import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/platform_utils.dart';
import 'app_menu_actions.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  static const _appIconAsset = 'assets/branding/QueryPod-512.png';
  static const _titleBarHeight = 34.0;
  static const _appIconSize = 18.0;
  static const _menuLabelTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  static const _menuItemTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const _submenuOffset = Offset(0, -4);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final chromeColor = _chromeColor(theme);

    return Container(
      key: const ValueKey('app-title-bar'),
      height: _titleBarHeight,
      decoration: BoxDecoration(
        color: chromeColor,
        border: Border(bottom: BorderSide(color: _separatorColor(theme))),
      ),
      child: Row(
        children: [
          if (!isMacOS) _buildAppIcon(theme),
          if (!isMacOS) _buildMenuBar(context, theme),
          Expanded(
            child: isDesktop
                ? const DragToMoveArea(child: SizedBox.expand())
                : const SizedBox.expand(),
          ),
          if (isDesktop && !isMacOS) const _DesktopCaptionButtons(),
        ],
      ),
    );
  }

  Widget _buildAppIcon(FThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 6),
      child: Image.asset(
        _appIconAsset,
        key: const ValueKey('app-title-bar-icon'),
        width: _appIconSize,
        height: _appIconSize,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  Widget _buildMenuBar(BuildContext context, FThemeData theme) {
    final topLevelStyle = _topLevelButtonStyle(theme);
    final menuSurfaceStyle = _menuSurfaceStyle(theme);
    final menuItemStyle = _menuItemStyle(theme);

    return Container(
      padding: const EdgeInsets.only(left: 6),
      child: MenuBar(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
        ),
        children: [
          SubmenuButton(
            alignmentOffset: _submenuOffset,
            style: topLevelStyle,
            menuStyle: menuSurfaceStyle,
            menuChildren: [
              MenuItemButton(
                onPressed: AppMenuActions.quit,
                semanticsLabel: 'Quit, shortcut Control Q',
                style: menuItemStyle,
                trailingIcon: Text(
                  'Ctrl+Q',
                  key: const ValueKey('quit-shortcut-hint'),
                  style: TextStyle(
                    color: _acceleratorColor(theme),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                child: const Text('Quit'),
              ),
            ],
            child: const Text('File'),
          ),
          SubmenuButton(
            alignmentOffset: _submenuOffset,
            style: topLevelStyle,
            menuStyle: menuSurfaceStyle,
            menuChildren: [
              MenuItemButton(
                onPressed: () => AppMenuActions.changeWorkspace(context),
                style: menuItemStyle,
                child: const Text('Change Workspace'),
              ),
            ],
            child: const Text('Workspace'),
          ),
        ],
      ),
    );
  }

  MenuStyle _menuSurfaceStyle(FThemeData theme) {
    final isDark = theme.colors.brightness == Brightness.dark;

    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll(_menuSurfaceColor(theme)),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: WidgetStatePropertyAll(
        Colors.black.withValues(alpha: isDark ? 0.34 : 0.12),
      ),
      elevation: const WidgetStatePropertyAll(6),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      minimumSize: const WidgetStatePropertyAll(Size(220, 0)),
      side: const WidgetStatePropertyAll(BorderSide.none),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  ButtonStyle _topLevelButtonStyle(FThemeData theme) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, _titleBarHeight)),
      fixedSize: const WidgetStatePropertyAll(Size.fromHeight(_titleBarHeight)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 9),
      ),
      foregroundColor: WidgetStatePropertyAll(theme.colors.foreground),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return _menuHoverColor(theme);
        }
        return Colors.transparent;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      textStyle: const WidgetStatePropertyAll(_menuLabelTextStyle),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  ButtonStyle _menuItemStyle(FThemeData theme) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(208, 28)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      ),
      foregroundColor: WidgetStatePropertyAll(theme.colors.foreground),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isEmpty) {
          return _menuItemBaseColor(theme);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return _menuItemHoverColor(theme);
        }
        return _menuItemBaseColor(theme);
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      textStyle: const WidgetStatePropertyAll(_menuItemTextStyle),
      alignment: Alignment.centerLeft,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _chromeColor(FThemeData theme) => Color.lerp(
    theme.colors.background,
    theme.colors.muted,
    theme.colors.brightness == Brightness.dark ? 0.22 : 0.5,
  )!;

  Color _separatorColor(FThemeData theme) => Color.lerp(
    theme.colors.border,
    theme.colors.foreground,
    theme.colors.brightness == Brightness.dark ? 0.18 : 0.08,
  )!;

  Color _menuSurfaceColor(FThemeData theme) => _menuHoverColor(theme);

  Color _menuHoverColor(FThemeData theme) => Color.lerp(
    theme.colors.muted,
    theme.colors.primary,
    theme.colors.brightness == Brightness.dark ? 0.14 : 0.08,
  )!;

  Color _menuItemBaseColor(FThemeData theme) =>
      Color.lerp(_menuSurfaceColor(theme), _menuSurfaceColor(theme), 1)!;

  Color _menuItemHoverColor(FThemeData theme) => Color.lerp(
    _menuItemBaseColor(theme),
    theme.colors.primary,
    theme.colors.brightness == Brightness.dark ? 0.2 : 0.12,
  )!;

  Color _acceleratorColor(FThemeData theme) => Color.lerp(
    theme.colors.mutedForeground,
    theme.colors.foreground,
    theme.colors.brightness == Brightness.dark ? 0.18 : 0.08,
  )!;
}

class _DesktopCaptionButtons extends StatefulWidget {
  const _DesktopCaptionButtons();

  @override
  State<_DesktopCaptionButtons> createState() => _DesktopCaptionButtonsState();
}

class _DesktopCaptionButtonsState extends State<_DesktopCaptionButtons>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadMaximizedState();
  }

  Future<void> _loadMaximizedState() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = isMaximized);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  Future<void> _toggleMaximized() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    await _loadMaximizedState();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final theme = context.theme;

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: _dividerColor(theme))),
      ),
      child: Row(
        key: const ValueKey('desktop-caption-buttons'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _captionButton(
            label: 'Minimize',
            child: WindowCaptionButton.minimize(
              brightness: brightness,
              onPressed: windowManager.minimize,
            ),
          ),
          _captionButton(
            label: _isMaximized ? 'Restore' : 'Maximize',
            child: _isMaximized
                ? WindowCaptionButton.unmaximize(
                    brightness: brightness,
                    onPressed: _toggleMaximized,
                  )
                : WindowCaptionButton.maximize(
                    brightness: brightness,
                    onPressed: _toggleMaximized,
                  ),
          ),
          _captionButton(
            label: 'Close',
            child: WindowCaptionButton.close(
              brightness: brightness,
              onPressed: AppMenuActions.quit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _captionButton({required String label, required Widget child}) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: child,
      ),
    );
  }

  Color _dividerColor(FThemeData theme) => Color.lerp(
    theme.colors.border,
    theme.colors.foreground,
    theme.colors.brightness == Brightness.dark ? 0.12 : 0.06,
  )!;
}
