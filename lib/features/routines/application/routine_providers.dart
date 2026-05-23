import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/notifications/notification_providers.dart';
import '../data/routine_repository.dart';
import 'routine_controller.dart';

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => RoutineRepository(
    ref.watch(appDatabaseProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
  ),
);

final routineControllerProvider = Provider<RoutineController>(
  (ref) => const RoutineController(),
);

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(routineRepositoryProvider).watchCategories(),
);

final routineDetailsProvider = StreamProvider<List<RoutineDetail>>(
  (ref) => ref.watch(routineRepositoryProvider).watchRoutineDetails(),
);

final routineDetailProvider = StreamProvider.family<RoutineDetail?, String>(
  (ref, routineId) =>
      ref.watch(routineRepositoryProvider).watchRoutineDetail(routineId),
);
