import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/calendar_repository.dart';
import 'calendar_controller.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => const CalendarRepository(),
);

final calendarControllerProvider = Provider<CalendarController>(
  (ref) => const CalendarController(),
);
