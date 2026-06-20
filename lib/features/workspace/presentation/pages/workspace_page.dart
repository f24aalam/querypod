import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../../connections/presentation/cubit/connection_state.dart';
import '../cubit/activity_cubit.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/workspace_metadata_cubit.dart';
import '../cubit/workspace_metadata_state.dart';
import '../widgets/activity_bar.dart';
import '../widgets/context_sidebar.dart';
import '../widgets/editor_area.dart';
import '../widgets/status_bar.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  ConnectionSessionIdentity? _loadedConnectionSession;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWorkspaceConnection(
      context.read<ConnectionCubit>().state.activeConnection,
    );
  }

  void _syncWorkspaceConnection(Connection? connection) {
    final workspaceCubit = context.read<WorkspaceMetadataCubit>();

    if (connection == null) {
      _loadedConnectionSession = null;
      workspaceCubit.clear();
      return;
    }

    final session = connection.sessionIdentity;
    if (_loadedConnectionSession == session &&
        workspaceCubit.state.connectionSession == session) {
      return;
    }

    _loadedConnectionSession = session;
    workspaceCubit.loadConnection(connection);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConnectionCubit, ConnectionsState>(
          listenWhen: (prev, curr) =>
              prev.activeConnection?.sessionIdentity !=
              curr.activeConnection?.sessionIdentity,
          listener: (context, state) {
            context.read<EditorTabsCubit>().closeTableTabs();
            _syncWorkspaceConnection(state.activeConnection);
          },
        ),
        BlocListener<ConnectionCubit, ConnectionsState>(
          listenWhen: (prev, curr) =>
              prev.openWorkspaceNonce != curr.openWorkspaceNonce,
          listener: (context, state) {
            context.read<ActivityCubit>().select(WorkbenchActivity.tables);
          },
        ),
        BlocListener<WorkspaceMetadataCubit, WorkspaceMetadataState>(
          listenWhen: (prev, curr) =>
              prev.feedbackNonce != curr.feedbackNonce &&
              curr.feedbackMessage != null,
          listener: (context, state) {
            showFToast(
              context: context,
              variant: state.feedbackIsError
                  ? FToastVariant.destructive
                  : FToastVariant.primary,
              title: Text(state.feedbackMessage!),
            );
          },
        ),
      ],
      child: ColoredBox(
        color: context.theme.colors.background,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  BlocBuilder<ConnectionCubit, ConnectionsState>(
                    buildWhen: (prev, curr) =>
                        prev.activeConnection?.sessionIdentity !=
                        curr.activeConnection?.sessionIdentity,
                    builder: (context, state) => ActivityBar(
                      canOpenWorkspace: state.activeConnection != null,
                    ),
                  ),
                  Expanded(
                    child: FResizable(
                      axis: Axis.horizontal,
                      children: [
                        FResizableRegion.fixed(
                          extent: 280,
                          minExtent: 160,
                          builder: (context, data, child) => child!,
                          child: const ContextSidebar(),
                        ),
                        FResizableRegion.flex(
                          flex: 1,
                          minFlex: 1,
                          builder: (context, data, child) => child!,
                          child: const EditorArea(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: context.theme.colors.border,
            ),
            const StatusBar(),
          ],
        ),
      ),
    );
  }
}
