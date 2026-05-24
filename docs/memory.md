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
- Phase 9 Calendar is implemented.
- Phase 10 Analytics is implemented.
- Phase 11 Smart Coach is implemented.
- Phase 12 Polish and Release Prep is implemented.

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
- Replaced the Calendar placeholder with a real `table_calendar` monthly view.
- Added `CalendarRepository` month summaries with planned, completed, skipped, missed, recovered, rescheduled, and score markers.
- Added selected-day details on the Calendar screen with score, status totals, and read-only routine cards.
- Updated selected past days to show unlogged planned routines as missed.
- Added a Calendar repository test covering month markers and selected date score activity.
- Replaced the Analytics placeholder with real local-data charts using `fl_chart`.
- Added analytics summary queries for daily scores, completion rate, category completion, focus minutes, most skipped routine, and recovery rate.
- Added summary stat tiles for average score, completed routines, total focus minutes, recovery rate, and most skipped routine.
- Added analytics empty states for missing score, completion, focus, and category data.
- Added an Analytics repository test covering scores, completion, categories, focus, skips, and recovery.
- Implemented a local `SmartCoachEngine` with overplanning, bad time, weak category, recovery, and good streak rules.
- Added `SmartCoachRepository` to build coaching context from local routines, schedules, logs, and categories.
- Replaced the Smart Coach placeholder with real rule-based insight cards and empty/error/loading states.
- Added Smart Coach engine and repository tests covering generated insights and empty-data behavior.
- Added a confirmed Settings action to clear local routines, logs, focus sessions, reminders, and scores while preserving default categories.
- Added `AppDatabase.clearUserData()` as the single local reset path.
- Expanded Android setup notes with manual APK testing steps and exact alarm permission guidance.
- Added a database reset test covering user-data clearing and category preservation.
- Fixed Android local notification setup for scheduled reminders: added scheduled notification receivers and boot-completed permission, removed exact alarm permission for MVP inexact scheduling, and kept the app offline-first with no cloud push/Firebase.
- Switched routine reminders from exact scheduling to `AndroidScheduleMode.inexactAllowWhileIdle`.
- Hardened notification permission handling so denied Android notification permission returns cleanly without scheduling or crashing.
- Expanded notification scheduler tests for flexible routine no-op behavior, global disable behavior, cancellation, and rescheduling order.
- Fixed Today timeline correctness: manual completion no longer stores impossible equal start/end timestamps, rescheduled logs resolve to active/missed from their updated planned window, Tomorrow creates a real one-time `specificDate` schedule, and stale entries update existing logs instead of creating duplicates.
- Added Today repository tests for manual completion timing, rescheduled active/missed behavior, move-to-tomorrow schedules, tomorrow timeline inclusion, and duplicate-log prevention.

## Commands Run

- `flutter create --platforms=android --project-name routine_os --org com.routineos .`
- `flutter pub add flutter_riverpod go_router drift sqlite3_flutter_libs path_provider path shared_preferences flutter_local_notifications timezone intl uuid fl_chart table_calendar`
- `flutter pub add --dev build_runner drift_dev flutter_lints`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `dart format lib/core/notifications test/core/notifications android/app/src/main/AndroidManifest.xml` (XML path was rejected by Dart formatter; Dart notification files were formatted)
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `dart format lib/features/today test/features/today`
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
- Calendar repository tests: passed.
- Analytics repository tests: passed.
- Smart Coach tests: passed.
- Local data reset test: passed.
- Android local notification scheduler tests: passed.
- Today timeline correctness tests: passed.
- Daily score side-effect tests: passed.
- Calendar score preview tests: passed.
- Settings persistence tests: passed.
- Theme mode provider test: passed.
- Settings clear-data test: passed.
- Routine form validation tests: passed.
- Reminder action-cancellation tests: passed.
- Release-prep clean pipeline: passed.
- Final hardening pass tests: passed.

## Known Issues

- Package resolver reports newer incompatible package versions are available. This is informational and does not block the build.
- `build_runner` reports that `--delete-conflicting-outputs` was ignored because the installed version no longer uses that option.
- Reminder timezone currently defaults to `Asia/Dhaka`; proper device timezone detection can be added later with a dedicated timezone plugin.
- Today still shows a simple progress card alongside the formal daily score card.
- Calendar markers use compact activity bars; richer per-status marker legends can be added during polish.

## Latest Update: Daily Score and Calendar Side Effects

- Moved the real `ScoreCalculator` into `lib/core/utils/score_calculator.dart`.
- Removed the old feature-local score calculator file.
- Updated daily score imports to use the shared core calculator.
- Changed recovery scoring so `recoveryOpportunityCount == 0` awards `0` recovery points instead of `10`.
- Added `saveScore` support to `TodayRepository.getTimelineForDate`; future dates never save or show a daily score.
- Calendar selected-day preview now calls the Today timeline in read-only score mode with `saveScore: false`.
- Future date previews still show planned routines as upcoming, without marking them missed and without writing `daily_scores`.
- Added regression tests for recovery scoring, empty score state, future preview score writes, and calendar read-only preview behavior.
- Ran `dart format lib test`.
- Ran `flutter analyze`: passed with no issues.
- Ran `flutter test`: passed.

## Latest Update: Settings Screen Completion

- Implemented `SettingsRepository` with SharedPreferences-backed theme, reminder, and start-of-week settings.
- Added `themeModeProvider`, `reminderSettingsProvider`, and `startOfWeekProvider`.
- Connected `MaterialApp.router` to the saved theme mode setting.
- Replaced the placeholder Settings screen with theme mode, reminder toggle, preparation/late reminder minute inputs, start-of-week selection, and clear-data confirmation.
- Updated notification settings and scheduling so preparation/late reminder defaults are stored and used by local notification scheduling.
- Connected start-of-week preference to the calendar view.
- Clear all data now cancels local routine notifications, clears user database rows, re-seeds default categories, and preserves SharedPreferences app settings.
- Added tests for SharedPreferences persistence, theme provider behavior, clear-data safety, and custom notification reminder offsets.
- Ran `dart format lib test`.
- Ran `flutter analyze`: passed with no issues.
- Ran `flutter test`: passed.

## Latest Update: Routine Form Cleanup

- Split `RoutineFormScreen` into private form sections: basic info, schedule, goal, recovery versions, and reminders.
- Added shared `RoutineFormData.validate()` rules used by create/update and the form submit path.
- Enforced required title/category/repeat days, positive target values where needed, non-overnight time ranges, positive recovery durations, and `mini <= medium <= full`.
- Hid target value/unit inputs for `simpleCheck` goals.
- Added helper messaging for recovery versions and fixed-time-only MVP reminder scheduling.
- Stabilized category/unit dropdown values during rebuilds.
- Added routine repository validation tests for empty title, invalid time range, missing repeat days, simple checks without targets, and target-required goal types.
- Ran `dart format` for touched files.
- Ran `flutter analyze`: passed with no issues.
- Ran `flutter test`: passed.

## Latest Update: Reminder Cancellation After User Actions

- Switched local routine reminder scheduling from indefinite weekly repeats to rolling one-time notifications for the next week.
- Added date-specific notification IDs while still canceling legacy per-weekday IDs for cleanup compatibility.
- Added scheduler APIs to cancel one reminder type or the remaining start/late/recovery reminders for a routine date.
- Wired Today manual complete and skip actions to cancel remaining same-day start/late/recovery reminders.
- Wired Focus session start and finish, including recovered sessions, to cancel remaining same-day start/late/recovery reminders.
- Preserved future-day reminders when canceling today's remaining reminders.
- Updated setup notes to document rolling one-time local reminder scheduling.
- Added tests for complete, skip, focus start/finish, custom reminder defaults, and future-day reminder preservation.
- Ran `dart format lib test`.
- Ran `flutter analyze`: passed with no issues.
- Ran `flutter test`: passed.

## Latest Update: Release Prep Cleanup

- Moved planning markdown files from the project root into `docs/`.
- Updated `docs/instruction.md` references to `docs/plan.md` and `docs/memory.md`.
- Removed local cache/build folders before the clean verification run: `.dart_tool/`, `build/`, `android/.gradle/`, and `android/.kotlin/`.
- Added `android/.kotlin/` to `.gitignore`.
- Rewrote `README.md` with app overview, offline-first scope, tech stack, run/codegen/test/build commands, Android notification notes, and MVP limitations.
- Confirmed `pubspec.lock` and `lib/core/database/app_database.g.dart` remain present.
- Ran `flutter clean`: passed.
- Ran `flutter pub get`: passed.
- Ran `dart run build_runner build --delete-conflicting-outputs`: passed; installed build_runner ignores that deprecated flag.
- Ran `flutter analyze`: passed with no issues.
- Ran `flutter test`: passed.
- Ran `flutter build apk --debug`: passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.

## Latest Update: Final APK Hardening

- Ran the requested clean baseline: `flutter clean`, `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, and `flutter test`.
- Added specific-date support to `RoutineReminderSchedule` so one-time schedule rows can receive local reminders.
- Kept weekly routines on rolling 8-day reminder scheduling and skipped reminder scheduling for past specific dates.
- Wired `moveToTomorrow` to request a one-time specific-date reminder schedule for the moved routine without replacing weekly reminders.
- Added Android notification status icon resource at `android/app/src/main/res/drawable/ic_stat_routine.xml`.
- Switched Android notification initialization from launcher icon to `ic_stat_routine`.
- Changed routine list ordering to active routines first.
- Added a comment explaining shared reminder SharedPreferences keys across settings classes.
- Added `android/local.properties` to `.gitignore`.
- Added tests for tomorrow specific-date reminders, past specific-date no-op behavior, active-first routine ordering, and move-to-tomorrow reminder scheduling.
- Ran final `flutter analyze`: passed with no issues.
- Ran final `flutter test`: passed.
- Ran final `flutter build apk --debug`: passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.
- Removed regenerated local machine metadata after the build: `.dart_tool/`, `.flutter-plugins-dependencies`, `android/.gradle/`, `android/.kotlin/`, and `android/local.properties`.

## Important Rules

- Always read `docs/plan.md` and `docs/memory.md` before implementing.
- Update `docs/memory.md` after each meaningful portion.
- Commit with a proper message after each portion.
- Push after each commit when possible.
- Keep MVP free and offline-first.

## Next Recommended Step

Manual APK testing and follow-up polish.

- Install `build/app/outputs/flutter-apk/app-debug.apk` on an Android device.
- Grant notification permission when prompted.
- Create routines, complete/skip/recover/focus them, and review Today, Calendar, Analytics, Smart Coach, and Settings reset behavior.

## Latest Update: Android Test Readiness Verification

- Confirmed local Flutter is `3.41.1` with Dart `3.11.0`, matching the project SDK requirement.
- Ran `flutter clean`: passed.
- Ran `flutter pub get`: passed.
- Ran `dart run build_runner build --delete-conflicting-outputs`: passed; installed build_runner ignores that deprecated flag.
- Ran `flutter analyze`: passed with no issues.
- Ran `flutter test`: passed with all tests green.
- Ran `flutter build apk --debug`: passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.
- Updated `android/.gitignore` so `gradle-wrapper.jar`, `gradlew`, and `gradlew.bat` are not ignored.
- Added the Gradle wrapper files to the repo so Android debug builds work from a fresh clone.
- Fixed weekly base reminder refreshes so they preserve existing one-time `specificDate` reminders for the same routine.
- Added a regression test proving a base weekly refresh does not cancel or overwrite the moved-to-tomorrow reminder.
- Re-verified specific-date reminder behavior: tomorrow schedules can schedule reminders, past specific dates do not schedule reminders, and weekly/flexible scheduling behavior remains covered.

## Latest Update: Final Behavior Correctness Fix

- Added `RoutineStatus.moved` and styled it like a non-action rescheduled state.
- Changed `moveToTomorrow` so the current-day log is saved as `moved` with the existing `Moved to yyyy-MM-dd` note.
- Today UI now treats `moved` as finished, so moved routines do not show missed recovery actions again.
- Updated later-today rescheduling to create/update a one-time `specificDate` schedule for the selected date using `reschedule-{routineId}-{dateKey}`.
- Later-today rescheduling now asks the notification scheduler to schedule local reminders for the new one-time time range.
- Current-day reminder cancellation now cancels preparation, start, late, and recovery reminders.
- Added/updated tests for moved status behavior, later-today specific-date schedules and reminder scheduling, and all-reminder cancellation after finish actions.
- Ran `flutter clean`: passed.
- Ran `flutter pub get`: passed.
- Ran `dart run build_runner build --delete-conflicting-outputs`: passed; installed build_runner ignores that deprecated flag.
- Ran `flutter analyze`: passed with no issues.
- Ran `flutter test`: passed with all 45 tests green.
- Ran `flutter build apk --debug`: passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.

## Latest Update: Start Of Week Options

- Changed start-of-week settings to offer Saturday and Sunday only.
- Set Saturday as the default/fallback start of week instead of Monday.
- Updated Calendar to use Saturday when the setting is Saturday or unavailable.
- Added a settings repository regression test for the Saturday default.
- Ran `flutter analyze`: passed with no issues.
- Ran targeted settings and calendar tests: passed.

## Latest Update: Settings Back Navigation

- Added optional app-bar leading support to `AppScaffold`.
- Changed the global Settings icon to push `/settings` so route history is preserved.
- Added a Settings screen back arrow that pops when possible and falls back to Today.
- Ran `flutter analyze`: passed with no issues.
- Ran targeted widget/settings tests: passed.

## Latest Update: Routine Repeat Creation Options

- Added explicit repeat choices to routine creation/editing: Today only, Every day, Weekdays, Weekends, and Custom days.
- Kept Every day as the default repeat choice for new routines.
- Today-only routines now save a one-time `specificDate` schedule with empty `repeatDays`.
- Repeating presets save weekly `repeatDays` with `specificDate = null`.
- Added helper text explaining recurring versus today-only behavior.
- Updated `RoutineFormData` and `RoutineRepository` to carry optional `specificDate` schedule data.
- Added tests for every-day, today-only, custom weekday, weekday-only, and weekend-only timeline behavior.
- Ran `flutter analyze`: passed with no issues.
- Ran `flutter test`: passed with all tests green.
