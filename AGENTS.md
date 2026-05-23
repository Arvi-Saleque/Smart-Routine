# RoutineOS Development Instructions

## Project Type

This is a Flutter offline-first routine, habit, and productivity tracker app.

## Core Principle

The MVP must work without internet and must not depend on a paid backend, paid AI API, paid database, paid server, or paid notification service.

## Stack

- Flutter
- Dart
- Riverpod
- go_router
- Drift plus SQLite
- flutter_local_notifications
- timezone
- fl_chart
- table_calendar

## Architecture

Use feature-first clean architecture.

Separate:

- UI
- controllers and providers
- repositories
- database
- business logic
- notification scheduling

Do not put database logic directly inside widgets.

## Folder Rules

Use this general structure:

```text
lib/
  app/
  core/
  shared/
  features/
```

Each feature should contain:

- `presentation`
- `application`
- `data`

## Code Quality

- Keep code readable.
- Avoid giant widgets.
- Extract reusable widgets.
- Avoid unnecessary dependencies.
- Do not add paid services.
- Do not add Firebase or Supabase in the MVP.
- Do not use paid AI APIs.
- Do not create fake placeholder logic where real local logic is simple.
- Run `flutter analyze` after changes.
- Fix analyzer errors before finishing.

## UX Rules

The app should feel like a serious productivity app:

- Clean
- Minimal
- Timeline-based
- Premium but simple
- Good spacing
- Clear typography
- Useful empty states
- Light and dark theme support

## MVP Priority

Build in this order:

1. Architecture
2. Routing
3. Local database
4. Routine CRUD
5. Today timeline
6. Focus session
7. Local reminders
8. Analytics
9. Rule-based Smart Coach

