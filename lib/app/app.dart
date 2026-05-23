import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class RoutineOSApp extends StatelessWidget {
  const RoutineOSApp({super.key});

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
