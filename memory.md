# Smart-Routine Memory

## Current State

- Repository contains an Android-first Flutter project for RoutineOS.
- `plan.md` defines the detailed implementation plan.
- The MVP target is an offline-first Android Flutter app using Riverpod, go_router, Drift SQLite, local notifications, fl_chart, and table_calendar.
- Phase 2 Drift database foundation is implemented.
- Phase 3 Routine CRUD is implemented.

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

## Verification

- `flutter analyze`: passed with no issues.
- `flutter test`: passed.
- `flutter build apk --debug`: passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.
- Database seed test: passed.
- Routine repository CRUD test: passed.

## Known Issues

- Package resolver reports newer incompatible package versions are available. This is informational and does not block the build.
- `build_runner` reports that `--delete-conflicting-outputs` was ignored because the installed version no longer uses that option.
- Today timeline still uses placeholder data and will be connected in Phase 4.
- Local reminder scheduling, analytics logic, focus timer behavior, and Smart Coach rules are intentionally not implemented yet.

## Important Rules

- Always read `plan.md` and `memory.md` before implementing.
- Update `memory.md` after each meaningful portion.
- Commit with a proper message after each portion.
- Push after each commit when possible.
- Keep MVP free and offline-first.

## Next Recommended Step

Begin Phase 4: Today Timeline.

- Load routines scheduled for the current date.
- Merge routines with routine logs.
- Detect upcoming, active, completed, skipped, and missed states.
- Render real timeline cards on Today screen.
- Implement complete and skip actions for today.
