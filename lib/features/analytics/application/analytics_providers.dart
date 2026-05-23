import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';
import 'analytics_controller.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => const AnalyticsRepository(),
);

final analyticsControllerProvider = Provider<AnalyticsController>(
  (ref) => const AnalyticsController(),
);
