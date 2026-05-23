import 'package:go_router/go_router.dart';

import '../features/analytics/presentation/analytics_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/coach/presentation/smart_coach_screen.dart';
import '../features/focus/presentation/focus_session_screen.dart';
import '../features/routines/presentation/routine_detail_screen.dart';
import '../features/routines/presentation/routine_form_screen.dart';
import '../features/routines/presentation/routine_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/today/presentation/today_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'today',
      builder: (context, state) => const TodayScreen(),
    ),
    GoRoute(
      path: '/routines',
      name: 'routines',
      builder: (context, state) => const RoutineListScreen(),
    ),
    GoRoute(
      path: '/routine/create',
      name: 'routine-create',
      builder: (context, state) => const RoutineFormScreen(),
    ),
    GoRoute(
      path: '/routine/:id/edit',
      name: 'routine-edit',
      builder: (context, state) {
        return RoutineFormScreen(routineId: state.pathParameters['id']);
      },
    ),
    GoRoute(
      path: '/routine/:id',
      name: 'routine-detail',
      builder: (context, state) {
        return RoutineDetailScreen(routineId: state.pathParameters['id'] ?? '');
      },
    ),
    GoRoute(
      path: '/focus/:routineId',
      name: 'focus',
      builder: (context, state) {
        return FocusSessionScreen(
          routineId: state.pathParameters['routineId'] ?? '',
          recoveryMode: state.uri.queryParameters['mode'] == 'mini',
        );
      },
    ),
    GoRoute(
      path: '/calendar',
      name: 'calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/coach',
      name: 'coach',
      builder: (context, state) => const SmartCoachScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
