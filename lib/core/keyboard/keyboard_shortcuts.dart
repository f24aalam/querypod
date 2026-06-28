import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class KeyboardShortcuts {
  static final bool isMacOS = Platform.isMacOS;

  // Save / Commit
  static SingleActivator commit = SingleActivator(
    LogicalKeyboardKey.keyS,
    control: !isMacOS,
    meta: isMacOS,
  );

  // Cancel / Escape
  static SingleActivator cancel = const SingleActivator(
    LogicalKeyboardKey.escape,
  );

  // Data grid actions
  static SingleActivator newRow = SingleActivator(
    LogicalKeyboardKey.keyN,
    control: !isMacOS,
    meta: isMacOS,
  );

  static SingleActivator createTable = SingleActivator(
    LogicalKeyboardKey.keyN,
    shift: true,
    control: !isMacOS,
    meta: isMacOS,
  );

  static SingleActivator refresh = SingleActivator(
    LogicalKeyboardKey.keyR,
    control: !isMacOS,
    meta: isMacOS,
  );

  static SingleActivator refreshF5 = const SingleActivator(
    LogicalKeyboardKey.f5,
  );

  // Query Editor
  static SingleActivator newQuery = SingleActivator(
    LogicalKeyboardKey.keyQ,
    control: !isMacOS,
    meta: isMacOS,
  );

  static SingleActivator runQuery = SingleActivator(
    LogicalKeyboardKey.enter,
    control: !isMacOS,
    meta: isMacOS,
  );

  // Sidebar navigation
  static SingleActivator connectionsSidebar = const SingleActivator(
    LogicalKeyboardKey.digit1,
    alt: true,
  );

  static SingleActivator tablesSidebar = const SingleActivator(
    LogicalKeyboardKey.digit2,
    alt: true,
  );

  static SingleActivator historySidebar = const SingleActivator(
    LogicalKeyboardKey.digit3,
    alt: true,
  );

  static SingleActivator querySidebar = const SingleActivator(
    LogicalKeyboardKey.digit4,
    alt: true,
  );

  // Tab navigation
  static SingleActivator nextTab = SingleActivator(
    LogicalKeyboardKey.tab,
    control: !isMacOS,
    meta: isMacOS,
  );

  static SingleActivator previousTab = SingleActivator(
    LogicalKeyboardKey.tab,
    shift: true,
    control: !isMacOS,
    meta: isMacOS,
  );

  static SingleActivator closeTab = SingleActivator(
    LogicalKeyboardKey.keyW,
    control: !isMacOS,
    meta: isMacOS,
  );

  // Helper to format shortcut labels for UI tooltips
  static String getModifierLabel() {
    return isMacOS ? 'Cmd' : 'Ctrl';
  }

  static String format(String key) {
    return '${getModifierLabel()}+$key';
  }
}
