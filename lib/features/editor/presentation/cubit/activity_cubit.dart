import 'package:flutter_bloc/flutter_bloc.dart';

enum WorkbenchActivity { connections, tables, history, query }

class ActivityCubit extends Cubit<WorkbenchActivity> {
  ActivityCubit() : super(WorkbenchActivity.connections);

  void select(WorkbenchActivity activity) => emit(activity);
}
