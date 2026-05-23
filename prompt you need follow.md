Codex Prompt: Build Free Offline-First Routine + Habit + Productivity App
You are an expert Flutter architect and senior mobile engineer.

Build an offline-first Flutter app for a smart routine, habit, and productivity tracker.

The app is NOT a basic habit checklist app. It should be a time-wise routine operating system where users can plan their day by time blocks, track completion, receive smart reminders, recover missed routines, and view analytics.

The app must be completely free to run for MVP:
- No paid backend
- No paid AI API
- No paid database
- No paid server
- No paid notification service
- No cloud functions
- No external SaaS dependency required for core features

Use this stack:
- Flutter
- Dart
- Riverpod for state management
- go_router for navigation
- Drift + SQLite for local database
- flutter_local_notifications for reminders
- timezone package for notification scheduling
- fl_chart for analytics charts
- table_calendar or custom calendar for calendar view
- shared_preferences only for lightweight app settings
- No Firebase in MVP unless added as optional placeholder later

Important architecture rules:
- The app must work offline.
- All routine data must be stored locally in SQLite.
- Use clean architecture / feature-first folder structure.
- Keep UI, state, repository, and database logic separated.
- Avoid hardcoded sample-only logic inside UI widgets.
- Use reusable widgets.
- Write readable, maintainable, production-style code.
- Add comments only where logic is non-trivial.
- Do not create a messy demo app.
Project Goal
Create a Flutter app named "RoutineOS".

Core idea:
A smart adaptive daily routine app where users can create fixed-time or flexible routines such as:

- Reading Bangla: 10:00 PM - 11:00 PM
- Coding Practice: 8:00 PM - 9:30 PM
- Drink Water: flexible target, 8 glasses daily
- Gym: 6:00 AM - 7:00 AM
- Work Block: 10:00 AM - 1:00 PM
- Sleep Preparation: 11:30 PM - 12:00 AM

The app should help users answer:
- What should I do now?
- What is next?
- What did I miss?
- Can I recover a missed routine with a mini version?
- Which category is weak?
- Which time slot is most productive?
- Am I overplanning?
Required MVP Features
Implement these MVP features first:

1. Today Timeline
- Show today’s routines in chronological order.
- Each routine card should show:
  - Routine title
  - Category
  - Start time
  - End time
  - Goal
  - Current status: upcoming, active, completed, skipped, missed
  - Buttons: Start, Complete, Skip, Reschedule
- Highlight the current active routine based on current time.

2. Routine Builder
Allow the user to create routines with:
- Title
- Description
- Category
- Routine type:
  - fixed_time
  - flexible
  - duration_based
  - count_based
- Goal type:
  - simple_check
  - duration
  - count
  - quantity
- Target value
- Target unit
  - minutes
  - pages
  - glasses
  - reps
  - hours
  - tasks
- Start time
- End time
- Repeat days
- Priority: low, medium, high
- Difficulty: easy, normal, hard
- Full duration
- Medium duration
- Mini duration
- Reminder enabled or disabled

3. Category System
Create built-in default categories:
- Reading
- Coding
- Work
- Study
- Health
- Spiritual
- Skill
- Break
- Planning
- Personal

Each category should have:
- id
- name
- icon name
- color value
- weekly target minutes

4. Completion Tracking
For each routine, user can:
- Mark completed
- Mark skipped
- Start focus session
- End focus session
- Add actual progress
- Add note
- Add mood
- Add difficulty feedback
- Add skip reason

Skip reasons:
- Too tired
- Busy
- Forgot
- Bad timing
- Not interested
- Emergency
- Overplanned
- Other

5. Focus Session
Create a focus screen:
- Shows routine title
- Shows timer
- Start / pause / resume / finish buttons
- Shows planned duration
- Allows user to log distraction
- Allows user to add note
- On finish, save actual duration into local database

6. Smart Reminder System
Use local notifications only.

For every fixed-time routine, schedule:
- Preparation reminder 10 minutes before start
- Start reminder at exact start time
- Late reminder 10 minutes after start
- Recovery reminder near the end if not started

Notification actions can be simple for now if action buttons are complex.
At minimum, tapping notification should open the app.

7. Missed Routine Recovery
If a routine is missed, show recovery suggestions:
- Start mini version
- Reschedule today
- Move to tomorrow
- Skip with reason

Every routine should support:
- Full version
- Medium version
- Mini version

Example:
Reading:
- Full: 60 min
- Medium: 30 min
- Mini: 10 min

8. Daily Productivity Score
Calculate a daily score out of 100.

Use this formula:
- Routine completion: 40 points
- On-time start rate: 20 points
- Focus minutes completed: 20 points
- Recovery completion: 10 points
- Category balance: 10 points

Show score on Today screen.

9. Analytics Screen
Show:
- Daily score
- Weekly completion rate
- Category-wise completion
- Total focus minutes
- Most skipped routine
- Best productive time range
- Recovery rate

Use fl_chart for charts.

10. Calendar Screen
Show monthly calendar.
When user taps a date, show:
- Routines planned for that day
- Completed routines
- Skipped routines
- Missed routines
- Score for that date

11. Smart Coach Screen
No paid AI API.
Build rule-based smart suggestions.

Examples:
- If completion rate of a routine is below 50%, suggest reducing duration.
- If many routines are skipped at night, suggest moving important tasks earlier.
- If total planned minutes are much higher than average completed minutes, warn about overplanning.
- If a routine is missed, suggest mini recovery.
- If a category is weak, suggest adding a small routine.

12. Settings Screen
Include:
- Notification toggle
- Default preparation reminder minutes
- Default late reminder minutes
- Theme mode
- Start of week
- Clear all data option
Required Screens
Create these screens:

1. TodayScreen
Route: /

Sections:
- Header with today date
- Daily score card
- Current active routine card
- Next routine card
- Timeline list
- Quick add routine button

2. RoutineListScreen
Route: /routines

Sections:
- All routines
- Filter by category
- Filter by active/inactive
- Add routine button

3. RoutineFormScreen
Route: /routine/create and /routine/:id/edit

Fields:
- title
- description
- category
- routine type
- goal type
- target value
- target unit
- start time
- end time
- repeat days
- priority
- difficulty
- full duration
- medium duration
- mini duration
- reminder enabled

4. RoutineDetailScreen
Route: /routine/:id

Show:
- Routine information
- Completion rate
- Recent logs
- Routine health score
- Edit button

5. FocusSessionScreen
Route: /focus/:routineId

Show:
- Timer
- Planned duration
- Start/pause/resume/finish
- Distraction log
- Note field
- Completion button

6. CalendarScreen
Route: /calendar

Show:
- Monthly calendar
- Selected day details

7. AnalyticsScreen
Route: /analytics

Show:
- Daily score chart
- Weekly completion chart
- Category chart
- Focus minutes chart
- Missed routines section

8. SmartCoachScreen
Route: /coach

Show:
- Rule-based suggestions
- Overplanning warnings
- Weak category insights
- Recovery suggestions

9. SettingsScreen
Route: /settings

Show:
- Reminder settings
- Theme setting
- Data settings
Folder Structure
Create this folder structure:

lib/
  main.dart

  app/
    app.dart
    router.dart
    theme.dart

  core/
    constants/
      app_constants.dart
    database/
      app_database.dart
      tables/
        categories_table.dart
        routines_table.dart
        routine_schedules_table.dart
        routine_logs_table.dart
        focus_sessions_table.dart
        reminders_table.dart
        daily_scores_table.dart
    notifications/
      notification_service.dart
      notification_scheduler.dart
    utils/
      date_time_utils.dart
      score_calculator.dart
      recurrence_utils.dart
    enums/
      routine_type.dart
      goal_type.dart
      routine_status.dart
      priority_level.dart
      difficulty_level.dart
      skip_reason.dart

  shared/
    widgets/
      app_scaffold.dart
      primary_button.dart
      empty_state.dart
      section_header.dart
      routine_card.dart
      score_card.dart
      category_chip.dart
    extensions/
      date_time_extensions.dart
      duration_extensions.dart

  features/
    today/
      presentation/
        today_screen.dart
        widgets/
      application/
        today_controller.dart
        today_providers.dart
      data/
        today_repository.dart

    routines/
      presentation/
        routine_list_screen.dart
        routine_form_screen.dart
        routine_detail_screen.dart
        widgets/
      application/
        routine_controller.dart
        routine_providers.dart
      data/
        routine_repository.dart

    focus/
      presentation/
        focus_session_screen.dart
      application/
        focus_controller.dart
        focus_providers.dart
      data/
        focus_repository.dart

    calendar/
      presentation/
        calendar_screen.dart
      application/
        calendar_controller.dart
        calendar_providers.dart
      data/
        calendar_repository.dart

    analytics/
      presentation/
        analytics_screen.dart
      application/
        analytics_controller.dart
        analytics_providers.dart
      data/
        analytics_repository.dart

    coach/
      presentation/
        smart_coach_screen.dart
      application/
        smart_coach_engine.dart
        smart_coach_providers.dart
      data/
        smart_coach_repository.dart

    settings/
      presentation/
        settings_screen.dart
      application/
        settings_controller.dart
        settings_providers.dart
      data/
        settings_repository.dart
Database Requirements
Use Drift + SQLite.

Create these tables:

1. categories
Fields:
- id TEXT PRIMARY KEY
- name TEXT
- iconName TEXT
- colorValue INTEGER
- weeklyTargetMinutes INTEGER
- createdAt DATETIME
- updatedAt DATETIME

2. routines
Fields:
- id TEXT PRIMARY KEY
- title TEXT
- description TEXT NULLABLE
- categoryId TEXT
- routineType TEXT
- goalType TEXT
- targetValue REAL NULLABLE
- targetUnit TEXT NULLABLE
- priority TEXT
- difficulty TEXT
- fullDurationMinutes INTEGER
- mediumDurationMinutes INTEGER
- miniDurationMinutes INTEGER
- isActive BOOLEAN
- reminderEnabled BOOLEAN
- createdAt DATETIME
- updatedAt DATETIME

3. routine_schedules
Fields:
- id TEXT PRIMARY KEY
- routineId TEXT
- startTimeMinutes INTEGER
- endTimeMinutes INTEGER
- repeatDays TEXT
- specificDate TEXT NULLABLE
- timezone TEXT
- createdAt DATETIME
- updatedAt DATETIME

Store startTimeMinutes and endTimeMinutes as minutes from midnight.
Example:
10:00 PM = 1320

4. routine_logs
Fields:
- id TEXT PRIMARY KEY
- routineId TEXT
- date TEXT
- status TEXT
- plannedStartTimeMinutes INTEGER
- plannedEndTimeMinutes INTEGER
- actualStartAt DATETIME NULLABLE
- actualEndAt DATETIME NULLABLE
- actualDurationMinutes INTEGER NULLABLE
- completionValue REAL NULLABLE
- mood TEXT NULLABLE
- difficultyFeedback TEXT NULLABLE
- skipReason TEXT NULLABLE
- note TEXT NULLABLE
- createdAt DATETIME
- updatedAt DATETIME

5. focus_sessions
Fields:
- id TEXT PRIMARY KEY
- routineId TEXT
- routineLogId TEXT NULLABLE
- startedAt DATETIME
- endedAt DATETIME NULLABLE
- plannedDurationMinutes INTEGER
- actualDurationMinutes INTEGER
- distractionCount INTEGER
- note TEXT NULLABLE
- createdAt DATETIME

6. reminders
Fields:
- id TEXT PRIMARY KEY
- routineId TEXT
- reminderType TEXT
- minutesOffset INTEGER
- enabled BOOLEAN
- createdAt DATETIME
- updatedAt DATETIME

7. daily_scores
Fields:
- id TEXT PRIMARY KEY
- date TEXT
- score INTEGER
- completionScore INTEGER
- onTimeScore INTEGER
- focusScore INTEGER
- recoveryScore INTEGER
- balanceScore INTEGER
- createdAt DATETIME
- updatedAt DATETIME
Smart Coach Rules
Build a rule-based SmartCoachEngine.

It should produce insight cards.

Insight model:
- id
- title
- message
- severity: info, warning, success
- category: overplanning, routine_health, recovery, timing, category_balance
- actionLabel
- createdAt

Rules:

1. Overplanning Rule
If total planned minutes today > average completed minutes from last 7 days * 1.5:
Show:
"You may be overplanning today. Your planned routine time is much higher than your recent average completion."

2. Bad Time Rule
If routines after 10 PM have completion rate below 40%:
Show:
"Your late-night routines are often missed. Move important routines earlier."

3. Weak Category Rule
If a category completion rate is below 50% this week:
Show:
"Your [category] routines are weak this week. Try a smaller routine."

4. Recovery Rule
If a routine is missed today and mini version exists:
Show:
"You missed [routine]. Try the mini version for [x] minutes."

5. Good Streak Rule
If a routine is completed 3 or more days in a row:
Show:
"You are building consistency in [routine]. Keep the streak alive."

6. Routine Health Score
Calculate for each routine:
routineHealth =
completionRate * 40
+ onTimeRate * 25
+ recoveryRate * 20
+ consistencyScore * 15

Return score out of 100.
UI/UX Requirements
Design style:
- Clean productivity app
- Premium but simple
- Soft cards
- Clear spacing
- Timeline-based layout
- Category colors
- No childish UI
- No clutter

Today Screen design:
- Top greeting/date
- Score card
- Active routine card
- Next routine card
- Timeline cards

Routine card states:
- Upcoming: normal card
- Active: highlighted card
- Completed: success style
- Skipped: muted style
- Missed: warning style

Each routine card should show:
- time range
- title
- category chip
- target
- status
- action buttons

Use reusable widgets:
- RoutineCard
- ScoreCard
- CategoryChip
- TimelineIndicator
- EmptyState
- SectionHeader
Development Instructions
Work step by step.

First:
1. Inspect current project structure.
2. If this is an empty Flutter project, create the architecture.
3. Add required dependencies to pubspec.yaml.
4. Implement enums and core models.
5. Implement Drift database tables.
6. Implement repositories.
7. Implement Riverpod providers.
8. Implement routing.
9. Implement Today screen.
10. Implement Routine CRUD.
11. Implement Focus session.
12. Implement local notification service.
13. Implement analytics.
14. Implement smart coach.

After each major step:
- Run flutter analyze.
- Fix errors.
- Do not leave broken imports.
- Do not leave TODO-only files.
- Do not use fake logic where real local logic is possible.
- Keep the app buildable.

Important:
If a package requires platform-specific setup, add the required Android/iOS notes in a SETUP_NOTES.md file.
First Task for Codex
Start by creating the full project architecture for RoutineOS.

Do the following now:

1. Inspect the Flutter project.
2. Add the required dependencies:
   - flutter_riverpod
   - go_router
   - drift
   - drift_flutter or sqlite3_flutter_libs as appropriate
   - path_provider
   - path
   - shared_preferences
   - flutter_local_notifications
   - timezone
   - intl
   - uuid
   - fl_chart
   - table_calendar

3. Create the folder structure exactly as requested.
4. Create enum files:
   - routine_type.dart
   - goal_type.dart
   - routine_status.dart
   - priority_level.dart
   - difficulty_level.dart
   - skip_reason.dart

5. Create app router with these routes:
   - /
   - /routines
   - /routine/create
   - /routine/:id
   - /routine/:id/edit
   - /focus/:routineId
   - /calendar
   - /analytics
   - /coach
   - /settings

6. Create placeholder screens for all routes, but make them visually clean, not empty white pages.

7. Create app theme with light and dark mode support.

8. Make the app compile successfully.

9. Run analysis and fix all issues.

Do not implement full business logic in this first step. Only create the architecture, routing, theme, dependencies, enums, and placeholder screens.
Recommended AGENTS.md for Codex

Create a file named:

AGENTS.md

in the project root and paste this:

# RoutineOS Development Instructions

## Project Type
This is a Flutter offline-first routine, habit, and productivity tracker app.

## Core Principle
The app must work without internet. MVP must not depend on a paid backend, paid AI API, paid database, or paid server.

## Stack
- Flutter
- Dart
- Riverpod
- go_router
- Drift + SQLite
- flutter_local_notifications
- timezone
- fl_chart
- table_calendar

## Architecture
Use feature-first clean architecture.

Separate:
- UI
- controllers/providers
- repositories
- database
- business logic
- notification scheduling

Do not put database logic directly inside widgets.

## Folder Rules
Use this general structure:

lib/
  app/
  core/
  shared/
  features/

Each feature should contain:
- presentation
- application
- data

## Code Quality
- Keep code readable.
- Avoid giant widgets.
- Extract reusable widgets.
- Avoid unnecessary dependencies.
- Do not add paid services.
- Do not add Firebase unless explicitly asked.
- Do not use AI APIs.
- Do not create fake placeholder logic where real local logic is simple.
- Run flutter analyze after changes.
- Fix all analyzer errors before finishing.

## UX Rules
The app should feel like a serious productivity app:
- Clean
- Minimal
- Timeline-based
- Premium cards
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

## Reminder System
Use local notifications only for MVP.

## Smart Coach
Use rule-based insights only. No paid AI APIs.