import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/focus_repository.dart';
import 'focus_controller.dart';

final focusRepositoryProvider = Provider<FocusRepository>(
  (ref) => const FocusRepository(),
);

final focusControllerProvider = Provider<FocusController>(
  (ref) => const FocusController(),
);
