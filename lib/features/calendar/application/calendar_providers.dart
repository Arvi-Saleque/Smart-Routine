import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import '../data/calendar_repository.dart';
import 'calendar_controller.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepository(ref.watch(appDatabaseProvider)),
);

final calendarControllerProvider = Provider<CalendarController>(
  (ref) => const CalendarController(),
);
