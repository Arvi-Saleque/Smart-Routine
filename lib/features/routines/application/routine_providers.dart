import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/routine_repository.dart';
import 'routine_controller.dart';

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => const RoutineRepository(),
);

final routineControllerProvider = Provider<RoutineController>(
  (ref) => const RoutineController(),
);
