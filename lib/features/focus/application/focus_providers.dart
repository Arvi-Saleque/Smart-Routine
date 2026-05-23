import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../data/focus_repository.dart';
import 'focus_controller.dart';

final focusRepositoryProvider = Provider<FocusRepository>(
  (ref) => FocusRepository(ref.watch(appDatabaseProvider)),
);

final focusControllerProvider = Provider<FocusController>(
  (ref) => FocusController(ref.watch(focusRepositoryProvider)),
);

final focusSessionsProvider = StreamProvider.family<List<FocusSession>, String>(
  (ref, routineId) =>
      ref.watch(focusRepositoryProvider).watchSessionsForRoutine(routineId),
);
