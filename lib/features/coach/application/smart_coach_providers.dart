import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/smart_coach_repository.dart';
import 'smart_coach_engine.dart';

final smartCoachRepositoryProvider = Provider<SmartCoachRepository>(
  (ref) => const SmartCoachRepository(),
);

final smartCoachEngineProvider = Provider<SmartCoachEngine>(
  (ref) => const SmartCoachEngine(),
);
