import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../platform_utils.dart';

class DesktopResizeFrame extends StatefulWidget {
  const DesktopResizeFrame({super.key, required this.child});

  final Widget child;

  @override
  State<DesktopResizeFrame> createState() => _DesktopResizeFrameState();
}

class _DesktopResizeFrameState extends State<DesktopResizeFrame>
    with WindowListener {
  bool _isMaximized = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    if (_usesResizeOverlay) {
      windowManager.addListener(this);
      _loadWindowState();
    }
  }

  bool get _usesResizeOverlay => isLinux || isWindows;

  Future<void> _loadWindowState() async {
    final isMaximized = await windowManager.isMaximized();
    final isFullScreen = await windowManager.isFullScreen();
    if (!mounted) return;
    setState(() {
      _isMaximized = isMaximized;
      _isFullScreen = isFullScreen;
    });
  }

  @override
  void dispose() {
    if (_usesResizeOverlay) {
      windowManager.removeListener(this);
    }
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

  @override
  void onWindowEnterFullScreen() {
    if (mounted) setState(() => _isFullScreen = true);
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) setState(() => _isFullScreen = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_usesResizeOverlay) return widget.child;

    return DragToResizeArea(
      enableResizeEdges: (_isMaximized || _isFullScreen) ? [] : null,
      resizeEdgeSize: 6,
      child: widget.child,
    );
  }
}
