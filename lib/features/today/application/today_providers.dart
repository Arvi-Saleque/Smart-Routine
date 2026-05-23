import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import '../data/today_repository.dart';
import 'today_controller.dart';

final todayRepositoryProvider = Provider<TodayRepository>(
  (ref) => TodayRepository(ref.watch(appDatabaseProvider)),
);

final todayControllerProvider = Provider<TodayController>(
  (ref) => TodayController(ref.watch(todayRepositoryProvider)),
);

final todayTimelineProvider = FutureProvider.autoDispose<TodayTimeline>((ref) {
  final now = DateTime.now();
  return ref.watch(todayRepositoryProvider).getTimelineForDate(now, now: now);
});
