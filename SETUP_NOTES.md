# RoutineOS Setup Notes

## Android Notifications

- Android 13 and newer require runtime notification permission before reminders can appear.
- Android 12 and newer have exact alarm behavior that must be handled carefully when scheduling precise routine reminders.
- The first architecture milestone only adds notification dependencies. Reminder initialization and permissions will be implemented in the local reminders phase.
- `flutter_local_notifications` requires Android core library desugaring, which is enabled in `android/app/build.gradle.kts`.
- Kotlin compilation is configured to run in-process to avoid Windows incremental-cache noise when dependencies live outside the project drive.
- Routine reminders now request notification permission at runtime and declare Android notification/exact alarm permissions in the manifest.
- MVP reminder timezone defaults to `Asia/Dhaka`; proper device timezone detection can be added later with a dedicated timezone plugin.
- For manual Android testing, install the debug APK, grant notification permission on first launch, and verify the Settings reminder toggle can pause and restore scheduled routine reminders.
- Some Android versions require users to allow exact alarms in system settings before precise reminders fire at the requested minute.

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
