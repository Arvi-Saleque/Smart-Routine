# RoutineOS Setup Notes

## Android Notifications

- Android 13 and newer require runtime notification permission before reminders can appear.
- Android 12 and newer have exact alarm behavior that must be handled carefully when scheduling precise routine reminders.
- The first architecture milestone only adds notification dependencies. Reminder initialization and permissions will be implemented in the local reminders phase.
- `flutter_local_notifications` requires Android core library desugaring, which is enabled in `android/app/build.gradle.kts`.
- Kotlin compilation is configured to run in-process to avoid Windows incremental-cache noise when dependencies live outside the project drive.

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
