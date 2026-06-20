import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:forui/forui.dart';

class QueryCodeEditor extends StatelessWidget {
  final CodeController controller;

  const QueryCodeEditor({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: CodeTheme(
          data: CodeThemeData(
            styles: isDark ? monokaiSublimeTheme : githubTheme,
          ),
          child: CodeField(
            controller: controller,
            expands: true,
            textStyle: TextStyle(
              fontSize: 14,
              height: 1.55,
              fontFamily: 'monospace',
              color: isDark ? const Color(0xFFF8F8F2) : theme.colors.foreground,
            ),
            background: theme.colors.background,
            gutterStyle: GutterStyle(
              width: 48,
              margin: 14,
              textStyle: TextStyle(
                fontSize: 13,
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
