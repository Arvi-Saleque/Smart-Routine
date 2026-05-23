import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_providers.dart';
import 'router.dart';
import 'theme.dart';

class RoutineOSApp extends ConsumerStatefulWidget {
  const RoutineOSApp({super.key});

  @override
  ConsumerState<RoutineOSApp> createState() => _RoutineOSAppState();
}

class _RoutineOSAppState extends ConsumerState<RoutineOSApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(notificationSchedulerProvider).initializeAndReschedule();
      } catch (error, stackTrace) {
        debugPrint('Notification initialization failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RoutineOS',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
    );
  }
}
