import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import 'settings_controller.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => const SettingsRepository(),
);

final settingsControllerProvider = Provider<SettingsController>(
  (ref) => const SettingsController(),
);
