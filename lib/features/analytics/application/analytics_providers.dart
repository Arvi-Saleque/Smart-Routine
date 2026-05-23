import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import '../data/analytics_repository.dart';
import 'analytics_controller.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.watch(appDatabaseProvider)),
);

final analyticsControllerProvider = Provider<AnalyticsController>(
  (ref) => const AnalyticsController(),
);

final analyticsSummaryProvider = FutureProvider.autoDispose<AnalyticsSummary>((
  ref,
) {
  return ref.watch(analyticsRepositoryProvider).getSummary();
});
