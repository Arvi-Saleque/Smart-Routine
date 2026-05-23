# RoutineOS Implementation Plan

## 1. Product Vision

RoutineOS is an offline-first routine, habit, and productivity app. It is not a basic habit checklist. The app should behave like a time-wise routine operating system that helps the user answer these daily questions:

- What should I do now?
- What is next?
- What did I miss?
- Can I recover a missed routine with a smaller version?
- Which category is weak?
- Which time slot works best for me?
- Am I overplanning my day?

The unique product idea is:

> A smart routine planner that helps users stay consistent, not perfect.

The most important product feature is Adaptive Routine Recovery. The app should assume that real life breaks plans. Instead of only marking habits as failed, it should help users recover through mini versions, rescheduling, skip reasons, and smart suggestions.

## 2. MVP Scope

The MVP must be completely free to run and must not require:

- Paid backend
- Paid AI API
- Paid database
- Paid server
- Paid cloud functions
- Paid notification service
- Internet connection for core app usage

The MVP will be Android-first. The app can later expand to Web and iOS, but the first implementation should focus on building a clean, working Android app that can be shared as an APK.

## 3. Technology Stack

Use this stack:

- Flutter
- Dart
- Riverpod for state management
- go_router for navigation
- Drift plus SQLite for local database
- sqlite3_flutter_libs for bundled SQLite support
- path_provider for database file location
- path for file path handling
- shared_preferences for lightweight app settings only
- flutter_local_notifications for local reminders
- timezone for time-zone-aware notification scheduling
- intl for date formatting
- uuid for IDs
- fl_chart for analytics charts
- table_calendar for monthly calendar UI

Do not add Firebase, Supabase, paid AI APIs, or external backend services in the MVP.

## 4. Architecture Principles

The project must use feature-first clean architecture.

Core rules:

- Keep UI separate from database logic.
- Keep widgets reusable and small.
- Keep state management in Riverpod providers and controllers.
- Keep data access inside repositories.
- Keep database schema inside Drift table definitions.
- Keep business logic inside services, engines, utilities, or repositories.
- Do not put SQL queries directly inside widgets.
- Do not hardcode app behavior inside placeholder widgets.
- Do not build a messy demo app.
- Every milestone should compile before moving to the next one.

Recommended layer responsibilities:

- `presentation`: screens and widgets
- `application`: controllers, providers, state classes, business orchestration
- `data`: repositories and data access logic
- `core`: database, notifications, utilities, constants, enums
- `shared`: reusable widgets and extensions
- `app`: app root, router, theme

## 5. Folder Structure

Create this structure:

```text
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
```

## 6. Route Map

Use `go_router`.

Required routes:

| Route | Screen | Purpose |
| --- | --- | --- |
| `/` | TodayScreen | Main daily timeline |
| `/routines` | RoutineListScreen | View and filter all routines |
| `/routine/create` | RoutineFormScreen | Create new routine |
| `/routine/:id` | RoutineDetailScreen | Routine details, logs, health score |
| `/routine/:id/edit` | RoutineFormScreen | Edit routine |
| `/focus/:routineId` | FocusSessionScreen | Timer and progress tracking |
| `/calendar` | CalendarScreen | Monthly routine history |
| `/analytics` | AnalyticsScreen | Productivity charts and insights |
| `/coach` | SmartCoachScreen | Rule-based suggestions |
| `/settings` | SettingsScreen | App preferences and data controls |

Use a shared app shell with bottom navigation for:

- Today
- Routines
- Calendar
- Analytics
- Coach
- Settings

If bottom navigation becomes too crowded, use five bottom items and put Settings in the app bar menu. Recommended MVP bottom navigation:

- Today
- Routines
- Calendar
- Analytics
- Coach

Settings can be accessed from a top-right icon.

## 7. Theme and UI Direction

The app should feel like a serious productivity tool:

- Clean
- Minimal
- Premium but simple
- Timeline-based
- Soft cards
- Strong spacing
- Clear typography
- Category colors
- Light and dark theme support
- No childish game UI
- No cluttered dashboards

Design rules:

- Use Material 3.
- Use cards for individual routine items, not for every page section.
- Use category chips with color and icon.
- Use state-specific routine styling:
  - Upcoming: neutral
  - Active: highlighted
  - Completed: success
  - Skipped: muted
  - Missed: warning
- Use readable time ranges everywhere.
- Use compact, useful action buttons.
- Keep text from overflowing on small screens.
- Avoid huge marketing-style hero sections.

## 8. Core Enums

Create enums as separate files.

### RoutineType

Values:

- `fixedTime`
- `flexible`
- `durationBased`
- `countBased`

Purpose:

- Fixed-time routines have a start and end time.
- Flexible routines can happen inside a wider window.
- Duration-based routines require a total duration before a deadline.
- Count-based routines track repetitions or quantity.

### GoalType

Values:

- `simpleCheck`
- `duration`
- `count`
- `quantity`

Purpose:

- Simple check tracks done or not done.
- Duration tracks minutes or hours.
- Count tracks reps, tasks, or sessions.
- Quantity tracks pages, glasses, steps, etc.

### RoutineStatus

Values:

- `upcoming`
- `active`
- `started`
- `completed`
- `skipped`
- `missed`
- `rescheduled`
- `recovered`

Purpose:

- Used by timeline, logs, analytics, and coach rules.

### PriorityLevel

Values:

- `low`
- `medium`
- `high`

### DifficultyLevel

Values:

- `easy`
- `normal`
- `hard`

### SkipReason

Values:

- `tooTired`
- `busy`
- `forgot`
- `badTiming`
- `notInterested`
- `emergency`
- `overplanned`
- `other`

## 9. Database Design

Use Drift with SQLite.

All IDs should be strings generated with `uuid`.

Dates:

- Store calendar dates as `TEXT` in `yyyy-MM-dd` format.
- Store timestamps as DateTime columns.
- Store routine schedule times as minutes from midnight.

Example:

- 10:00 PM = 1320
- 11:00 PM = 1380

### categories

Fields:

- `id TEXT PRIMARY KEY`
- `name TEXT`
- `iconName TEXT`
- `colorValue INTEGER`
- `weeklyTargetMinutes INTEGER`
- `createdAt DATETIME`
- `updatedAt DATETIME`

Default categories:

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

### routines

Fields:

- `id TEXT PRIMARY KEY`
- `title TEXT`
- `description TEXT NULLABLE`
- `categoryId TEXT`
- `routineType TEXT`
- `goalType TEXT`
- `targetValue REAL NULLABLE`
- `targetUnit TEXT NULLABLE`
- `priority TEXT`
- `difficulty TEXT`
- `fullDurationMinutes INTEGER`
- `mediumDurationMinutes INTEGER`
- `miniDurationMinutes INTEGER`
- `isActive BOOLEAN`
- `reminderEnabled BOOLEAN`
- `createdAt DATETIME`
- `updatedAt DATETIME`

### routine_schedules

Fields:

- `id TEXT PRIMARY KEY`
- `routineId TEXT`
- `startTimeMinutes INTEGER`
- `endTimeMinutes INTEGER`
- `repeatDays TEXT`
- `specificDate TEXT NULLABLE`
- `timezone TEXT`
- `createdAt DATETIME`
- `updatedAt DATETIME`

`repeatDays` should store weekday numbers as a serialized string for MVP, for example:

```text
1,2,3,4,5
```

Where:

- 1 = Monday
- 7 = Sunday

### routine_logs

Fields:

- `id TEXT PRIMARY KEY`
- `routineId TEXT`
- `date TEXT`
- `status TEXT`
- `plannedStartTimeMinutes INTEGER`
- `plannedEndTimeMinutes INTEGER`
- `actualStartAt DATETIME NULLABLE`
- `actualEndAt DATETIME NULLABLE`
- `actualDurationMinutes INTEGER NULLABLE`
- `completionValue REAL NULLABLE`
- `mood TEXT NULLABLE`
- `difficultyFeedback TEXT NULLABLE`
- `skipReason TEXT NULLABLE`
- `note TEXT NULLABLE`
- `createdAt DATETIME`
- `updatedAt DATETIME`

### focus_sessions

Fields:

- `id TEXT PRIMARY KEY`
- `routineId TEXT`
- `routineLogId TEXT NULLABLE`
- `startedAt DATETIME`
- `endedAt DATETIME NULLABLE`
- `plannedDurationMinutes INTEGER`
- `actualDurationMinutes INTEGER`
- `distractionCount INTEGER`
- `note TEXT NULLABLE`
- `createdAt DATETIME`

### reminders

Fields:

- `id TEXT PRIMARY KEY`
- `routineId TEXT`
- `reminderType TEXT`
- `minutesOffset INTEGER`
- `enabled BOOLEAN`
- `createdAt DATETIME`
- `updatedAt DATETIME`

Reminder types:

- `preparation`
- `start`
- `late`
- `recovery`
- `dailyReview`
- `weeklyReview`

### daily_scores

Fields:

- `id TEXT PRIMARY KEY`
- `date TEXT`
- `score INTEGER`
- `completionScore INTEGER`
- `onTimeScore INTEGER`
- `focusScore INTEGER`
- `recoveryScore INTEGER`
- `balanceScore INTEGER`
- `createdAt DATETIME`
- `updatedAt DATETIME`

## 10. Default Category Seed Data

Seed default categories on first app launch after database initialization.

Suggested values:

| Name | Icon name | Color direction | Weekly target |
| --- | --- | --- | --- |
| Reading | menu_book | Blue | 300 |
| Coding | code | Purple | 600 |
| Work | work | Indigo | 900 |
| Study | school | Teal | 600 |
| Health | fitness_center | Green | 300 |
| Spiritual | self_improvement | Amber | 240 |
| Skill | psychology | Cyan | 300 |
| Break | coffee | Orange | 420 |
| Planning | event_note | Pink | 120 |
| Personal | home | Brown | 300 |

Use integer Flutter color values in the database.

## 11. Main Feature Requirements

### 11.1 Today Timeline

This is the main screen and should be the heart of the app.

Sections:

- Header with current date
- Daily score card
- Current active routine card
- Next routine card
- Timeline list
- Quick add routine button

Each timeline card should show:

- Time range
- Routine title
- Category chip
- Goal summary
- Status
- Priority or difficulty indicator
- Start button
- Complete button
- Skip button
- Reschedule button

Timeline behavior:

- Show today's routines in chronological order.
- Highlight current active routine based on the current time.
- Show missed routines when current time is after end time and no completion log exists.
- Show completed/skipped/recovered state from `routine_logs`.
- If there are no routines, show an empty state with a create routine button.

### 11.2 Routine Builder

Fields:

- Title
- Description
- Category
- Routine type
- Goal type
- Target value
- Target unit
- Start time
- End time
- Repeat days
- Priority
- Difficulty
- Full duration
- Medium duration
- Mini duration
- Reminder enabled

Validation:

- Title is required.
- Category is required.
- Routine type is required.
- Goal type is required.
- Fixed-time routines require start and end time.
- End time must be after start time for same-day routines.
- At least one repeat day is required unless it is a specific-date routine.
- Mini duration must be less than or equal to medium duration.
- Medium duration must be less than or equal to full duration.
- Target value must be positive when goal type needs quantity, count, or duration.

MVP target units:

- minutes
- pages
- glasses
- reps
- hours
- tasks

### 11.3 Routine List

Sections:

- Search or filter bar
- Category filter
- Active or inactive filter
- Routine list
- Add routine button

Each routine row should show:

- Title
- Category
- Schedule summary
- Repeat days
- Active state
- Completion rate preview

Actions:

- Open detail
- Edit
- Toggle active or inactive

### 11.4 Routine Detail

Show:

- Routine title
- Category
- Type
- Goal
- Time range
- Repeat days
- Full, medium, mini durations
- Reminder state
- Completion rate
- Routine health score
- Recent logs
- Edit button

Routine health score formula:

```text
routineHealth =
completionRate * 40
+ onTimeRate * 25
+ recoveryRate * 20
+ consistencyScore * 15
```

Return score out of 100.

### 11.5 Focus Session

The focus screen should support:

- Routine title
- Category
- Planned duration
- Countdown or elapsed timer
- Start
- Pause
- Resume
- Finish
- Complete
- Add note
- Log distraction
- Show distraction count

On finish:

- Save focus session.
- Save actual duration.
- Update or create routine log.
- Let user enter completion value if needed.
- Let user add mood and difficulty feedback.

### 11.6 Completion Tracking

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

Completion styles:

- Simple check
- Duration input
- Count input
- Quantity input

### 11.7 Missed Routine Recovery

If a routine is missed, show recovery suggestions:

- Start mini version
- Reschedule today
- Move to tomorrow
- Skip with reason

Every routine should have:

- Full version
- Medium version
- Mini version

Example:

- Full: 60 minutes
- Medium: 30 minutes
- Mini: 10 minutes

Recovery should count differently from perfect completion. A recovery should not be treated as failure. It should support a recovery streak.

### 11.8 Smart Reminder System

Use local notifications only.

For every fixed-time routine with reminders enabled, schedule:

- Preparation reminder 10 minutes before start
- Start reminder at exact start time
- Late reminder 10 minutes after start
- Recovery reminder near the end if not started

MVP behavior:

- Notification tap opens the app.
- Action buttons can be added later.
- Reminder scheduling should be updated when a routine changes.
- Reminder scheduling should be cancelled when a routine is disabled or deleted.

Reminder examples:

- Preparation: "Reading starts in 10 minutes. Prepare your book."
- Start: "Start Bangla Reading now. Goal: 20 pages."
- Late: "You missed the start. Start a shorter session?"
- Recovery: "You can still recover with a 10-minute mini session."

### 11.9 Daily Productivity Score

Score out of 100.

Formula:

- Routine completion: 40 points
- On-time start rate: 20 points
- Focus minutes completed: 20 points
- Recovery completion: 10 points
- Category balance: 10 points

Implementation notes:

- Score should be calculated locally.
- Score should be saved in `daily_scores`.
- Recalculate when logs or focus sessions change.
- If no routines exist for the day, score should be 0 or show no-score empty state.

### 11.10 Analytics

Show:

- Daily score
- Weekly completion rate
- Category-wise completion
- Total focus minutes
- Most skipped routine
- Best productive time range
- Recovery rate

Charts:

- Daily score chart
- Weekly completion chart
- Category chart
- Focus minutes chart

Use `fl_chart`.

### 11.11 Calendar

Use `table_calendar`.

Monthly calendar should show:

- Selected date
- Planned routines
- Completed routines
- Skipped routines
- Missed routines
- Score for selected date

Visual ideas:

- Use small status dots under calendar days.
- Use score color intensity for completion.
- Show selected-day summary below the calendar.

### 11.12 Smart Coach

No paid AI API in MVP.

Build rule-based insights.

Insight model:

- `id`
- `title`
- `message`
- `severity`
- `category`
- `actionLabel`
- `createdAt`

Severity values:

- `info`
- `warning`
- `success`

Insight categories:

- `overplanning`
- `routineHealth`
- `recovery`
- `timing`
- `categoryBalance`

Rules:

1. Overplanning rule
   - If total planned minutes today is greater than average completed minutes from last 7 days multiplied by 1.5.
   - Message: "You may be overplanning today. Your planned routine time is much higher than your recent average completion."

2. Bad time rule
   - If routines after 10 PM have completion rate below 40 percent.
   - Message: "Your late-night routines are often missed. Move important routines earlier."

3. Weak category rule
   - If a category completion rate is below 50 percent this week.
   - Message: "Your [category] routines are weak this week. Try a smaller routine."

4. Recovery rule
   - If a routine is missed today and mini version exists.
   - Message: "You missed [routine]. Try the mini version for [x] minutes."

5. Good streak rule
   - If a routine is completed 3 or more days in a row.
   - Message: "You are building consistency in [routine]. Keep the streak alive."

### 11.13 Settings

Settings screen should include:

- Notification toggle
- Default preparation reminder minutes
- Default late reminder minutes
- Theme mode
- Start of week
- Clear all data option

Use `shared_preferences` only for lightweight settings:

- Theme mode
- Notification master toggle
- Default reminder minutes
- Start of week

Do not store routine data in shared preferences.

## 12. Repository Responsibilities

### RoutineRepository

Responsibilities:

- Create routine
- Update routine
- Delete routine
- Toggle active state
- Fetch routine by ID
- Fetch all routines
- Fetch routines by category
- Fetch routines scheduled for a date
- Save schedules
- Validate conflicts if needed

### TodayRepository

Responsibilities:

- Load today's routines
- Load logs for today
- Build timeline item data
- Detect active routine
- Detect next routine
- Detect missed routines
- Save completion, skip, recovery, or reschedule actions

### FocusRepository

Responsibilities:

- Start focus session
- Pause or resume timer state in controller
- Finish focus session
- Save actual duration
- Attach focus session to routine log
- Update distraction count and note

### AnalyticsRepository

Responsibilities:

- Calculate daily score
- Load weekly completion rate
- Load category completion
- Load focus minutes
- Find most skipped routine
- Calculate recovery rate
- Calculate best productive time range

### CalendarRepository

Responsibilities:

- Load routines and logs by selected date
- Load score by selected date
- Provide calendar status markers

### SmartCoachRepository

Responsibilities:

- Load data required by the rule engine
- Return generated insight cards

### SettingsRepository

Responsibilities:

- Read and write lightweight settings
- Clear all local app data when user confirms

## 13. Riverpod Provider Plan

Create providers by feature.

Core providers:

- `appDatabaseProvider`
- `notificationServiceProvider`
- `notificationSchedulerProvider`
- `settingsRepositoryProvider`

Routine providers:

- `routineRepositoryProvider`
- `routineListProvider`
- `routineDetailProvider`
- `routineControllerProvider`

Today providers:

- `todayRepositoryProvider`
- `todayTimelineProvider`
- `activeRoutineProvider`
- `nextRoutineProvider`
- `dailyScoreProvider`
- `todayControllerProvider`

Focus providers:

- `focusRepositoryProvider`
- `focusControllerProvider`
- `focusTimerProvider`

Analytics providers:

- `analyticsRepositoryProvider`
- `analyticsSummaryProvider`
- `weeklyStatsProvider`
- `categoryStatsProvider`

Calendar providers:

- `calendarRepositoryProvider`
- `selectedDateProvider`
- `selectedDateSummaryProvider`

Coach providers:

- `smartCoachRepositoryProvider`
- `smartCoachInsightsProvider`

Settings providers:

- `settingsControllerProvider`
- `themeModeProvider`
- `notificationSettingsProvider`

## 14. Notification Plan

Use `flutter_local_notifications` and `timezone`.

Implementation steps:

1. Initialize timezone database.
2. Initialize local notification plugin.
3. Request Android notification permission where required.
4. Create notification channels.
5. Schedule notifications when routines are created or edited.
6. Cancel notifications when routines are deleted or reminders disabled.
7. Reschedule all active routine notifications on app startup.

Notification IDs:

- Generate stable integer notification IDs based on routine ID and reminder type.
- Avoid random notification IDs because cancellation must work.

Reminder types:

- Preparation: negative offset, usually -10 minutes.
- Start: offset 0.
- Late: positive offset, usually +10 minutes.
- Recovery: near routine end or configurable.

MVP limitation:

- Notification action buttons are optional for later.
- Tapping a notification should open the app.

## 15. Recurrence Plan

For MVP, support weekly repeat days.

Example:

- Monday, Wednesday, Friday
- Every day
- Weekdays
- Weekends

Implementation:

- Store repeat days as weekday numbers.
- Build helper methods in `recurrence_utils.dart`.
- Use selected date to decide if a routine is scheduled.

Future support:

- Specific one-time date
- Monthly recurrence
- Custom intervals

## 16. Score Calculation Plan

Create `score_calculator.dart`.

Inputs:

- Planned routine count
- Completed routine count
- Started-on-time count
- Planned focus minutes
- Actual focus minutes
- Recovered routine count
- Category distribution

Output:

- Total score
- Completion score
- On-time score
- Focus score
- Recovery score
- Balance score

Rules:

- Clamp total score between 0 and 100.
- Avoid division by zero.
- If there are no planned routines, return empty score state or 0.
- Recovery should add score, not punish the user.
- Overplanning can affect coach warnings first, not score penalty in MVP.

## 17. UI Screen Details

### TodayScreen

Layout:

- App header with date and greeting
- ScoreCard
- Active routine section
- Next routine section
- Timeline section
- Floating action button for quick routine creation

Empty state:

- Message: "No routines planned for today."
- Button: "Create routine"

### RoutineListScreen

Layout:

- Header
- Category filter chips
- Active/inactive segmented filter
- Routine list
- Add button

Empty state:

- Message: "Build your first routine."
- Button: "Add routine"

### RoutineFormScreen

Layout:

- Basic info section
- Category section
- Schedule section
- Goal section
- Versions section
- Reminder section
- Save button

Mode:

- Create mode for `/routine/create`
- Edit mode for `/routine/:id/edit`

### RoutineDetailScreen

Layout:

- Title and category
- Schedule summary
- Goal summary
- Health score
- Completion stats
- Recent logs
- Edit button

### FocusSessionScreen

Layout:

- Routine title
- Timer
- Planned duration
- Main control button
- Pause/resume controls
- Distraction button
- Note field
- Finish button

### CalendarScreen

Layout:

- Monthly calendar
- Selected day score
- Selected day routine list
- Status summary

### AnalyticsScreen

Layout:

- Score trend chart
- Weekly completion chart
- Category chart
- Focus minutes chart
- Missed routines section
- Recovery rate card

### SmartCoachScreen

Layout:

- Insight cards
- Overplanning warning
- Recovery suggestions
- Weak category suggestions
- Positive streak messages

### SettingsScreen

Layout:

- Theme mode control
- Notification toggle
- Reminder minute settings
- Start of week control
- Clear data section

## 18. Implementation Phases

### Phase 1: Project Setup and Architecture

Goal:

- Create a compiling Flutter app shell.

Tasks:

- Create Flutter project in the current folder.
- Add dependencies.
- Create folder structure.
- Add `AGENTS.md`.
- Add enums.
- Add app theme.
- Add router.
- Add clean placeholder screens.
- Add shared widgets.
- Run `flutter analyze`.

Acceptance criteria:

- App compiles.
- All routes exist.
- No analyzer errors.
- Placeholder screens look clean.
- No business logic is implemented yet.

### Phase 2: Drift Database Foundation

Goal:

- Add local database schema and seed categories.

Tasks:

- Add Drift table files.
- Create `AppDatabase`.
- Add migrations setup.
- Add category seed logic.
- Add basic database provider.
- Generate Drift code.
- Run analysis.

Acceptance criteria:

- App opens with database initialized.
- Default categories are inserted once.
- No broken generated imports.

### Phase 3: Routine CRUD

Goal:

- Let user create, view, edit, deactivate, and delete routines.

Tasks:

- Implement routine repository.
- Implement routine controller.
- Build routine form.
- Save routine and schedule.
- Show routine list.
- Show routine detail.
- Add validation.

Acceptance criteria:

- User can create a fixed-time routine.
- User can edit it.
- User can view it in routine list and detail.
- Data persists after app restart.

### Phase 4: Today Timeline

Goal:

- Show scheduled routines for the selected day.

Tasks:

- Implement recurrence helper.
- Fetch today's scheduled routines.
- Merge routines with logs.
- Detect active, upcoming, missed, completed, skipped states.
- Implement timeline UI.
- Implement complete and skip actions.

Acceptance criteria:

- Today screen shows routines in chronological order.
- Active routine is highlighted.
- Completed and skipped states persist.
- Missed routines are shown after their end time.

### Phase 5: Focus Session

Goal:

- Add real focus timer and save focus data.

Tasks:

- Implement focus controller.
- Add timer logic.
- Add pause and resume.
- Add distraction count.
- Add note field.
- Save focus session.
- Update routine log on finish.

Acceptance criteria:

- User can start a focus session from a routine.
- Timer works.
- Distractions and notes are saved.
- Actual duration is saved.

### Phase 6: Local Reminders

Goal:

- Schedule local routine notifications.

Tasks:

- Initialize notifications.
- Request permissions.
- Create notification channels.
- Schedule preparation, start, late, and recovery reminders.
- Cancel and reschedule reminders on routine update.
- Add settings toggle.

Acceptance criteria:

- Fixed-time routines can schedule reminders.
- Disabled reminders do not fire.
- Updating a routine updates its reminders.

### Phase 7: Recovery System

Goal:

- Help users recover missed routines.

Tasks:

- Add recovery options to missed routine cards.
- Start mini version from missed state.
- Reschedule today.
- Move to tomorrow.
- Skip with reason.
- Save recovered state in logs.

Acceptance criteria:

- Missed routines show recovery actions.
- Mini recovery creates a recovered log.
- Skip reason is saved.

### Phase 8: Daily Score

Goal:

- Calculate and display productivity score.

Tasks:

- Implement score calculator.
- Calculate score from logs and focus sessions.
- Save daily score.
- Show score card on Today screen.
- Refresh score after completion, skip, recovery, or focus finish.

Acceptance criteria:

- Score updates after routine actions.
- Score breakdown is stored.
- Score is visible on Today screen.

### Phase 9: Calendar

Goal:

- Show monthly history and selected-day routine details.

Tasks:

- Add table calendar.
- Load selected date data.
- Show completed, skipped, missed, and planned routines.
- Show selected date score.

Acceptance criteria:

- User can tap a date.
- Selected date summary updates.
- Calendar markers show routine activity.

### Phase 10: Analytics

Goal:

- Show charts and productivity summary.

Tasks:

- Add analytics repository queries.
- Add daily score chart.
- Add weekly completion chart.
- Add category completion chart.
- Add focus minutes chart.
- Show most skipped routine.
- Show recovery rate.

Acceptance criteria:

- Analytics screen uses real local data.
- Charts handle empty states.
- No fake chart-only logic remains.

### Phase 11: Smart Coach

Goal:

- Add rule-based suggestions without AI API.

Tasks:

- Implement SmartCoachEngine.
- Add overplanning rule.
- Add bad time rule.
- Add weak category rule.
- Add recovery rule.
- Add good streak rule.
- Show insight cards.

Acceptance criteria:

- Coach suggestions come from local data.
- Empty state appears when there are not enough logs.
- No paid AI API is used.

### Phase 12: Polish and Release Prep

Goal:

- Prepare the app for manual APK testing.

Tasks:

- Improve responsiveness.
- Add loading states.
- Add error states.
- Add confirmation dialogs for destructive actions.
- Add setup notes for Android notification permissions.
- Run full analysis.
- Run tests.
- Build debug APK.

Acceptance criteria:

- App has no analyzer errors.
- App has no obvious broken routes.
- App can be installed and tested on Android.

## 19. Testing Plan

### Static checks

Run:

```text
flutter analyze
```

After every major phase.

### Unit tests

Test:

- Date time utilities
- Recurrence utilities
- Score calculator
- Smart coach rules
- Routine validation

### Widget tests

Test:

- App starts successfully.
- Today screen renders empty state.
- Routine form validates required fields.
- Routine card displays correct status style.
- Settings screen renders core controls.

### Repository tests

If practical with Drift test database:

- Insert default categories.
- Create routine.
- Create schedule.
- Create log.
- Query routines by date.
- Calculate analytics from local logs.

### Manual testing

Test:

- Create routine.
- Edit routine.
- Complete routine.
- Skip routine with reason.
- Start focus session.
- Finish focus session.
- View calendar date.
- View analytics.
- See coach suggestions after enough activity.
- Toggle dark mode.
- Toggle reminders.

## 20. Data Safety and Edge Cases

Handle:

- No routines created.
- Routine with missing optional description.
- No analytics data yet.
- No categories loaded yet.
- Notification permission denied.
- Routine end time before start time.
- Same routine completed twice on same day.
- App opened after a routine was missed.
- User clears all data.
- User disables reminders globally.
- User changes theme mode.

MVP decisions:

- Overnight routines can be blocked in MVP with validation.
- Timezone changes can be handled later.
- Calendar sync is not part of MVP.
- Cloud backup is not part of MVP.
- AI chat is not part of MVP.

## 21. Future Features After MVP

Version 2:

- Templates
- Energy-based planning
- Smart rescheduling
- Distraction analytics
- Routine health dashboard
- Weekly review generation
- Calendar heatmap
- Better notification actions

Version 3:

- Optional Firebase backup
- Optional account login
- Multi-device sync
- Advanced AI coach
- Wearable integration
- Template marketplace
- Web dashboard

## 22. First Coding Milestone Checklist

The first implementation task should only do this:

- Create Flutter project.
- Add dependencies.
- Create requested folder structure.
- Create enum files.
- Create app router.
- Create placeholder screens.
- Create app theme with light and dark mode.
- Create shared placeholder widgets.
- Add `AGENTS.md`.
- Make the app compile.
- Run `flutter analyze`.
- Fix analyzer issues.

Do not implement full database logic, reminders, analytics, or coach rules in the first coding milestone.

