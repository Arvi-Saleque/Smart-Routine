# RoutineOS

RoutineOS is an offline-first Flutter app for planning routines, tracking daily progress, recovering missed habits, and reviewing local productivity insights.

The MVP is designed to work without a cloud backend, Firebase, Supabase, paid AI APIs, or remote push notifications. Routine data, logs, focus sessions, reminders, and scores live on the device.

## Tech Stack

- Flutter and Dart
- Riverpod for state management
- go_router for navigation
- Drift and SQLite for local persistence
- flutter_local_notifications for local Android reminders
- shared_preferences for app settings
- table_calendar for calendar views
- fl_chart for analytics charts

## Project Docs

Planning and agent notes live in `docs/`:

- `docs/plan.md`
- `docs/instruction.md`
- `docs/memory.md`
- `docs/featrures by gpt.md`
- `docs/problem or app i want.md`
- `docs/prompt you need follow.md`
- `docs/tech stac by gpt.md`

## Run Locally

```bash
flutter pub get
flutter run
```

## Generate Drift Code

Run this after changing Drift tables or database-related generated code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Do not delete `lib/core/database/app_database.g.dart` unless it is regenerated.

## Tests And Checks

```bash
flutter analyze
flutter test
```

For a debug Android APK:

```bash
flutter build apk --debug
```

## Android Notification Notes

- RoutineOS uses local scheduled notifications only.
- Android 13 and newer require runtime notification permission.
- The MVP uses inexact local scheduling with `AndroidScheduleMode.inexactAllowWhileIdle`.
- Exact alarm permission is intentionally not required for the MVP.
- Reminders are scheduled as rolling one-time local notifications for the next week so same-day late/recovery reminders can be canceled after completion, skip, or recovery without destroying future reminders.
- Some OEM Android builds may delay or block background alarms when battery saver or aggressive standby modes are enabled.

See `SETUP_NOTES.md` for more Android setup details.

## Current MVP Limitations

- Android is the main target for the MVP.
- Reminder timezone currently falls back to `Asia/Dhaka`; device timezone detection can be improved later.
- Reminder delivery is local and best-effort, subject to OS battery rules.
- Overnight routines are blocked for now.
- Reminder scheduling currently supports fixed-time routines only.
- Smart Coach is local rule-based insight, not cloud AI.
- There is no account sync, multi-device backup, or remote backend yet.
