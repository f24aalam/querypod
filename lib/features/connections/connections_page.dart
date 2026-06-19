import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../workspace/activity_bar.dart';
import '../workspace/status_bar.dart';
import 'connection_form.dart';
import 'connection_list_panel.dart';

class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ColoredBox(
      color: theme.colors.background,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const ActivityBar(),
                Expanded(
                  child: FResizable(
                    axis: Axis.horizontal,
                    children: [
                      FResizableRegion.fixed(
                        extent: 240,
                        minExtent: 160,
                        builder: (context, data, child) => child!,
                        child: const ConnectionListPanel(),
                      ),
                      FResizableRegion.flex(
                        flex: 1,
                        minFlex: 1,
                        builder: (context, data, child) => child!,
                        child: const ConnectionForm(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.colors.border),
          const StatusBar(),
        ],
      ),
    );
  }
}
