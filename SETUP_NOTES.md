# RoutineOS Setup Notes

## Android Notifications

- Android 13 and newer require runtime notification permission before reminders can appear.
- Android 13 and newer show a runtime notification permission prompt. If the user denies permission, RoutineOS keeps running and does not schedule local reminders.
- RoutineOS uses local scheduled notifications only. It does not use Firebase, cloud push notifications, or a remote backend.
- RoutineOS uses inexact local reminder scheduling for the MVP. This avoids requiring exact alarm permission while still allowing Android to deliver reminders in a battery-aware way.
- Android 12 and newer restrict exact alarms. If exact minute-level reminders are added later, the app must add `SCHEDULE_EXACT_ALARM`, request/guide the user through exact alarm access, and document the behavior.
- `flutter_local_notifications` requires Android core library desugaring, which is enabled in `android/app/build.gradle.kts`.
- Kotlin compilation is configured to run in-process to avoid Windows incremental-cache noise when dependencies live outside the project drive.
- Routine reminders request notification permission at runtime and declare scheduled-notification receivers plus boot-completed permission in the manifest so reminders can survive reboot/package replacement.
- RoutineOS schedules rolling one-time local reminders for the next week instead of indefinite weekly repeating alarms. This lets the app cancel today's late/recovery reminder after completion, skip, or recovery without deleting future-day reminders.
- MVP reminder timezone defaults to `Asia/Dhaka`; proper device timezone detection can be added later with a dedicated timezone plugin.
- For manual Android testing, install the debug APK, grant notification permission on first launch, and verify the Settings reminder toggle can pause and restore scheduled routine reminders.
- Some OEM Android builds may delay or block scheduled alarms while the app is in the background, especially when battery saver or aggressive app standby modes are enabled.

## Drift

- Drift generated files require `build_runner`.
- After database tables are added, run:

```text
flutter pub run build_runner build --delete-conflicting-outputs
```

## Offline MVP

- Firebase is intentionally not included in the MVP.
- Supabase is intentionally not included in the MVP.
- Paid AI APIs are intentionally not included in the MVP.
- Core routine data should live in local SQLite through Drift.

## Manual APK Test Checklist

- Create a fixed-time routine with reminders enabled.
- Confirm it appears on Today, Calendar, Analytics, and Smart Coach after local activity exists.
- Complete, skip, recover, and focus a routine to verify local logs, scores, charts, and insights update.
- Use Settings to clear local data and confirm default categories remain.
