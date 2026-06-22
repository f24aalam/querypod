import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:forui/forui.dart';

import '../../../connections/domain/entities/connection.dart';
import 'create_database_dialog.dart';

class QueryCodeEditor extends StatelessWidget {
  final CodeController controller;
  final bool isRunning;
  final VoidCallback? onRun;
  final List<String> databases;
  final String? selectedDatabase;
  final ValueChanged<String?>? onDatabaseChanged;
  final Connection? connection;

  const QueryCodeEditor({
    required this.controller,
    this.isRunning = false,
    this.onRun,
    this.databases = const [],
    this.selectedDatabase,
    this.onDatabaseChanged,
    this.connection,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
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
                    color: isDark
                        ? const Color(0xFFF8F8F2)
                        : theme.colors.foreground,
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
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (databases.isNotEmpty) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 140,
                        child: FSelect<String>.search(
                          items: {for (final db in databases) db: db},
                          size: FTextFieldSizeVariant.sm,
                          hint: 'Select database',
                          clearable: false,
                          searchFieldProperties: const FSelectSearchFieldProperties(
                            hint: 'Search databases...',
                          ),
                          contentConstraints: const FAutoWidthPortalConstraints(
                            maxHeight: 300,
                          ),
                          prefixBuilder: (context, fieldStyle, widget) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.storage_outlined,
                              size: 14,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          suffixBuilder: (context, fieldStyle, widget) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.arrow_drop_down,
                              size: 14,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          control: FSelectControl.lifted(
                            value: databases.contains(selectedDatabase)
                                ? selectedDatabase
                                : null,
                            onChange: onDatabaseChanged ?? (_) {},
                          ),
                        ),
                      ),
                      if (connection != null && connection!.type != ConnectionType.sqlite) ...[
                        const SizedBox(width: 8),
                        FButton.icon(
                          onPress: () {
                            CreateDatabaseDialog.show(
                              context,
                              connection!,
                            );
                          },
                          size: FButtonSizeVariant.sm,
                          variant: FButtonVariant.outline,
                          child: const Icon(Icons.add, size: 16),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                FButton(
                  onPress: isRunning ? null : onRun,
                  size: FButtonSizeVariant.sm,
                  child: isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Run'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
