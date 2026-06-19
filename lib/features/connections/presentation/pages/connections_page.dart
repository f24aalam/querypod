import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../widgets/connection_form.dart';
import '../widgets/connection_list_panel.dart';

class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FResizable(
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
    );
  }
}
