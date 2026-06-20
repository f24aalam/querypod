import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../../connections/presentation/cubit/connection_state.dart';
import '../cubit/workspace_metadata_cubit.dart';
import '../cubit/workspace_metadata_state.dart';
import '../widgets/workspace_scaffold.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  String? _loadedConnectionId;

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
      _loadedConnectionId = null;
      workspaceCubit.clear();
      return;
    }

    if (_loadedConnectionId == connection.id &&
        workspaceCubit.state.connectionId == connection.id) {
      return;
    }

    _loadedConnectionId = connection.id;
    workspaceCubit.loadConnection(connection);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConnectionCubit, ConnectionsState>(
          listenWhen: (prev, curr) =>
              prev.activeConnection?.id != curr.activeConnection?.id,
          listener: (context, state) {
            _syncWorkspaceConnection(state.activeConnection);
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
      child: const WorkspaceScaffold(),
    );
  }
}
