import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import '../data/smart_coach_repository.dart';
import 'smart_coach_engine.dart';

final smartCoachRepositoryProvider = Provider<SmartCoachRepository>(
  (ref) => SmartCoachRepository(
    ref.watch(appDatabaseProvider),
    engine: ref.watch(smartCoachEngineProvider),
  ),
);

final smartCoachEngineProvider = Provider<SmartCoachEngine>(
  (ref) => const SmartCoachEngine(),
);

final smartCoachInsightsProvider =
    FutureProvider.autoDispose<List<SmartCoachInsight>>((ref) {
      return ref.watch(smartCoachRepositoryProvider).getInsights();
    });
