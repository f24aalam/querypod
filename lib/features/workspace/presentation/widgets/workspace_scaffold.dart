import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'row_detail_panel.dart';
import 'table_list_panel.dart';
import 'table_results_panel.dart';

class WorkspaceScaffold extends StatelessWidget {
  const WorkspaceScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return FResizable(
      axis: Axis.horizontal,
      children: [
        FResizableRegion.fixed(
          extent: 300,
          minExtent: 140,
          builder: (context, data, child) => child!,
          child: const TableListPanel(),
        ),
        FResizableRegion.flex(
          flex: 1,
          minFlex: 1,
          builder: (context, data, child) => child!,
          child: FResizable(
            axis: Axis.horizontal,
            children: [
              FResizableRegion.flex(
                flex: 1,
                minFlex: 1,
                builder: (context, data, child) => child!,
                child: const TableResultsPanel(),
              ),
              FResizableRegion.fixed(
                extent: 280,
                minExtent: 200,
                builder: (context, data, child) => child!,
                child: const RowDetailPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
