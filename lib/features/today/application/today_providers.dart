import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/today_repository.dart';
import 'today_controller.dart';

final todayRepositoryProvider = Provider<TodayRepository>(
  (ref) => const TodayRepository(),
);

final todayControllerProvider = Provider<TodayController>(
  (ref) => const TodayController(),
);
