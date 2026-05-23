# Smart-Routine Memory

## Current State

- Repository contains an Android-first Flutter project for RoutineOS.
- `plan.md` defines the detailed implementation plan.
- The MVP target is an offline-first Android Flutter app using Riverpod, go_router, Drift SQLite, local notifications, fl_chart, and table_calendar.
- Phase 2 Drift database foundation is implemented.
- Phase 3 Routine CRUD is implemented.
- Phase 4 Today Timeline is implemented.
- Phase 5 Focus Session is implemented.
- Phase 6 Local Reminders is implemented.
- Phase 7 Recovery System is implemented.
- Phase 8 Daily Score is implemented.

## Completed

- Created detailed implementation plan in `plan.md`.
- Added repository instructions in `instruction.md`.
- Added initial project README.
- Added Flutter-focused `.gitignore`.
- Implemented Phase 1 project setup and architecture.
- Scaffolded Android Flutter project with project name `routine_os`.
- Added required runtime dependencies and dev dependencies.
- Added app root, Material 3 light/dark theme, and go_router route map.
- Added clean placeholder screens for Today, Routines, Routine Form, Routine Detail, Focus, Calendar, Analytics, Smart Coach, and Settings.
- Added shared UI shells: `AppScaffold`, `PrimaryButton`, `EmptyState`, `SectionHeader`, `RoutineCard`, `ScoreCard`, and `CategoryChip`.
- Added core enums for routine type, goal type, routine status, priority, difficulty, and skip reason.
- Added feature-first application/data placeholder classes and providers.
- Added `AGENTS.md` and `SETUP_NOTES.md`.
- Enabled Android core library desugaring for `flutter_local_notifications`.
- Configured Kotlin compilation in-process to avoid Windows incremental-cache noise.
- Implemented Drift table definitions for categories, routines, routine schedules, routine logs, focus sessions, reminders, and daily scores.
- Added `AppDatabase` with schema version 1, local SQLite file opening, foreign key enabling, and migration setup.
- Added idempotent default category seeding for the 10 MVP categories.
- Added `appDatabaseProvider` for Riverpod-managed database lifecycle.
- Generated Drift code in `lib/core/database/app_database.g.dart`.
- Added a database test that confirms default categories are seeded once.
- Connected `RoutineRepository` to `AppDatabase`.
- Implemented routine create, read, update, pause/activate, and delete operations with schedule persistence.
- Added Riverpod providers for categories, routine lists, and routine detail streams.
- Replaced routine placeholder screens with database-backed Routine List, Routine Form, and Routine Detail screens.
- Added form validation for title, category, time range, repeat days, target value, and full/medium/mini duration order.
- Added shared date/time and recurrence utilities for schedule formatting and repeat-day handling.
- Added a repository test covering create, update, pause, and delete behavior.
- Connected Today screen to real routines scheduled for the current weekday.
- Implemented Today timeline merging scheduled routines with routine logs.
- Added status detection for upcoming, active, missed, completed, and skipped routines.
- Added complete and skip actions that write local routine logs.
- Added skip reason selection dialog.
- Added active routine, next routine, timeline list, and daily progress summary from local data.
- Added a Today repository test covering scheduled routine loading, completion logs, and skip logs.
- Connected `/focus/:routineId` to real routine data.
- Implemented focus timer UI with start, pause, resume, finish, distraction count, notes, and recent sessions.
- Implemented `FocusRepository` save flow that writes `focus_sessions` and updates or creates completed `routine_logs`.
- Added focus session Riverpod providers and controller.
- Added a Focus repository test covering saved focus sessions and completed routine logs.
- Implemented local notification service initialization with timezone support and Android notification permission request.
- Added a routine notification scheduler for preparation, start, late, and recovery reminders.
- Added stable per-routine/per-weekday notification IDs and reminder metadata persistence in the `reminders` table.
- Wired routine create, update, pause/activate, and delete flows to schedule, reschedule, or cancel reminders.
- Initialized and rescheduled reminders on app startup.
- Added Android notification and exact alarm permissions.
- Added a shared_preferences-backed global routine reminders toggle on the Settings screen.
- Added scheduler tests for fixed-time reminder scheduling, non-schedulable routine cancellation, and global reminder disable behavior.
- Extended routine repository tests to protect paused routines from being rescheduled by edits.
- Added recovery actions to missed routine cards: mini recovery, reschedule later today, move to tomorrow, and skip.
- Added mini recovery mode for the Focus screen using the routine mini duration and saving logs with `recovered` status.
- Added Today repository recovery methods that save rescheduled logs and recovery notes locally.
- Updated routine cards to support additional contextual action buttons.
- Added recovery tests for missed routine rescheduling and recovered mini focus sessions.
- Added a local daily score calculator using the planned 40/20/20/10/10 weighted formula.
- Added `DailyScoreRepository` to calculate and persist score breakdowns in `daily_scores`.
- Recalculate and save daily scores when Today loads and when Focus sessions finish.
- Updated Today screen to show the stored daily score plus a breakdown message.
- Added score calculator tests and persistence checks for Today and Focus flows.

## Commands Run

- `flutter create --platforms=android --project-name routine_os --org com.routineos .`
- `flutter pub add flutter_riverpod go_router drift sqlite3_flutter_libs path_provider path shared_preferences flutter_local_notifications timezone intl uuid fl_chart table_calendar`
- `flutter pub add --dev build_runner drift_dev flutter_lints`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter clean; flutter pub get; flutter build apk --debug`
- `flutter pub run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

## Verification

- `flutter analyze`: passed with no issues.
- `flutter test`: passed.
- `flutter build apk --debug`: passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.
- Database seed test: passed.
- Routine repository CRUD test: passed.
- Today repository timeline/log test: passed.
- Focus repository save test: passed.
- Notification scheduler tests: passed.
- Recovery system tests: passed.
- Daily score tests: passed.

## Known Issues

- Package resolver reports newer incompatible package versions are available. This is informational and does not block the build.
- `build_runner` reports that `--delete-conflicting-outputs` was ignored because the installed version no longer uses that option.
- Analytics logic and Smart Coach rules are intentionally not implemented yet.
- Reminder timezone currently defaults to `Asia/Dhaka`; proper device timezone detection can be added later with a dedicated timezone plugin.
- Move-to-tomorrow recovery is stored as a rescheduled log note for now; a richer future version can create one-off tomorrow schedule instances.
- Today still shows a simple progress card alongside the formal daily score card.

## Important Rules

- Always read `plan.md` and `memory.md` before implementing.
- Update `memory.md` after each meaningful portion.
- Commit with a proper message after each portion.
- Push after each commit when possible.
- Keep MVP free and offline-first.

## Next Recommended Step

Begin Phase 9: Calendar.

- Add table calendar.
- Load selected date data.
- Show completed, skipped, missed, and planned routines.
- Show selected date score.
