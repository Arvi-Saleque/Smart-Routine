I’ll treat “completely free” as: no paid server, no paid database, no paid notification service, no paid AI API at MVP stage. I’ll separate what is free for development/MVP from what may need payment after real users grow.

Thought for 46s

For completely free MVP, build it as an offline-first mobile app. Do not start with paid AI, paid server, paid cron jobs, paid cloud functions, or paid app-store release.

The best stack for you:

Recommended Free Tech Stack
1. Frontend / Mobile App

Use:

Flutter + Dart

Why Flutter is the best choice for this app:

One codebase for Android, iOS, Web, Desktop later.
You already work with Flutter.
Perfect for timeline UI, calendar UI, charts, routine cards, reminders, animations.
Can build APK and test directly on Android without publishing to Play Store.
Great for offline-first local storage.

For now, target:

Android first
Then Web dashboard later
Then iOS only when you are ready to pay for Apple Developer Program

Important reality: building/testing is free, but publishing is not fully free. Google Play Console has a US$25 one-time registration fee, and Apple Developer Program is US$99/year. So for a zero-cost MVP, distribute Android APK manually or use internal testing outside the public store.

2. App Architecture

Use this architecture:

Flutter App
│
├── UI Layer
│   ├── Today Timeline
│   ├── Routine Builder
│   ├── Focus Timer
│   ├── Calendar View
│   ├── Analytics
│   └── Smart Coach
│
├── State Management
│   └── Riverpod
│
├── Local Data Layer
│   ├── SQLite / Drift
│   ├── Routine Tables
│   ├── Logs
│   ├── Reminder Rules
│   └── Analytics Cache
│
├── Reminder Engine
│   ├── Local Notifications
│   ├── Snooze
│   ├── Missed Detection
│   └── Recovery Suggestions
│
├── Smart Engine
│   ├── Rule-based insights
│   ├── Overplanning detection
│   ├── Best time analysis
│   └── Routine health score
│
└── Optional Cloud Sync Later
    ├── Firebase Spark
    └── Firestore

The key point: the app should work without internet.

A routine app must not depend on cloud every time because reminders, timers, daily planning, and completion tracking should work even when the user is offline.

3. Local Database

Use:

Drift + SQLite

This is better than simple key-value storage because your app has relational data.

You need to store:

Routines
Categories
Time blocks
Repeat rules
Daily logs
Completion history
Skip reasons
Reminder settings
Focus sessions
Analytics

For this type of app, SQLite is more suitable than simple local storage.

Suggested local tables:

users
categories
routines
routine_schedules
routine_logs
focus_sessions
reminders
skip_reasons
daily_scores
weekly_reviews
routine_insights
settings

Example:

routines
id
title
description
category_id
routine_type
goal_type
target_value
target_unit
priority
difficulty
full_duration
medium_duration
mini_duration
is_active
created_at
updated_at
routine_schedules
id
routine_id
start_time
end_time
repeat_type
repeat_days
specific_date
timezone
routine_logs
id
routine_id
date
status
planned_start_time
planned_end_time
actual_start_time
actual_end_time
actual_duration
completion_value
mood
difficulty_feedback
skip_reason
note
created_at

This structure will let you build real analytics later.

4. State Management

Use:

Riverpod

Do not use basic setState for this app.

Your app will have many connected parts:

Current active routine
Today’s timeline
Upcoming reminders
Timer state
Daily score
Calendar logs
Analytics filters
Theme
Settings

Riverpod will help keep the app clean.

Suggested Riverpod providers:

routineRepositoryProvider
todayTimelineProvider
activeRoutineProvider
focusTimerProvider
dailyScoreProvider
weeklyStatsProvider
categoryStatsProvider
reminderServiceProvider
smartCoachProvider
settingsProvider
5. Routing

Use:

go_router

Routes:

/
/today
/routine/create
/routine/:id
/routine/:id/edit
/focus/:routineId
/calendar
/calendar/:date
/analytics
/coach
/templates
/settings

This will keep navigation clean and scalable.

6. Reminder System

For the free version, use:

Local Notifications

Do not start with server push notifications.

Why?

Because your main reminders are device-based:

“Reading starts at 10:00 PM”
“Coding starts in 10 minutes”
“You missed gym”
“Try mini version”
“Daily review time”

These can be handled locally without any paid server.

Reminder flow:

Routine created
↓
Generate reminder rules
↓
Schedule local notifications
↓
At start time: send notification
↓
If user does not start: mark as pending/missed
↓
Send recovery notification

Reminder types:

before_start_reminder
start_reminder
late_reminder
recovery_reminder
daily_review_reminder
weekly_review_reminder

Example:

For:

Reading Bangla
10:00 PM - 11:00 PM

The app schedules:

9:50 PM  → Prepare for reading
10:00 PM → Start reading now
10:10 PM → Still not started?
10:45 PM → Mini recovery option
11:05 PM → Mark completed / missed

This is possible without backend.

7. Cloud Backend: Use Firebase Only When Needed

For a completely free MVP, you can build the first version without backend.

But if you want login and backup, use:

Firebase Spark Plan

Firebase has a no-cost Spark plan, and Google’s docs say it does not require payment information to get started. Firebase also lists Authentication, Cloud Messaging, Crashlytics, Remote Config, and similar services as no-cost products, while Firestore has a free quota.

Use Firebase for:

Need	Firebase Service
Login	Firebase Auth
Cloud backup	Firestore
Push notification later	Firebase Cloud Messaging
Crash reports	Crashlytics
Basic analytics	Firebase Analytics
Remote config	Firebase Remote Config

Important: Firestore free quota is limited. Google lists the free Firestore quota as 1 GiB stored data, 50,000 reads/day, 20,000 writes/day, 20,000 deletes/day, and 10 GiB outbound data/month. That is enough for MVP if you design carefully.

Firebase Auth also has limits; Firebase’s current docs mention 3,000 daily active users on no-cost Spark for most sign-in providers under Firebase Authentication with Identity Platform.

Firebase Cloud Messaging is good for future remote notifications because Firebase says FCM has no cost.

8. What Not to Use in Free MVP

Avoid these at first:

Avoid Firebase Cloud Functions

Firebase docs list Cloud Functions access under Blaze/pay-as-you-go behavior, not pure Spark-only development. So if your goal is “no payment card, no billing risk,” avoid Cloud Functions now.

Avoid paid AI APIs

Do not use OpenAI/Gemini/Claude API in MVP if your condition is fully free.

Instead, build a rule-based Smart Coach first.

Example:

If routine completion rate < 50%
and skip reason = "too tired"
and routine time > 10:30 PM
then suggest moving routine earlier.

This feels smart without AI cost.

Avoid server cron jobs

Cron jobs are needed for server reminders, weekly reports, email notifications, etc.

For now, generate weekly reports inside the app when the user opens the app.

Avoid SMS login

SMS auth can become paid or restricted. Use email/password, Google sign-in, or anonymous login.

Avoid image/file upload

Routine apps do not need file storage in MVP. File storage increases cost risk.

9. Best Free Stack Version

Use this:

Mobile App:
Flutter

Language:
Dart

State Management:
Riverpod

Navigation:
go_router

Local Database:
Drift + SQLite

Small Local Settings:
SharedPreferences

Local Notifications:
flutter_local_notifications

Date/Time:
timezone package

Charts:
fl_chart

Calendar:
table_calendar or custom calendar

Animations:
Flutter implicit animations + Lottie optional

Backend:
None for v1

Optional Cloud Backup:
Firebase Spark + Firestore

Auth:
Firebase Auth email / Google / anonymous

Crash:
Firebase Crashlytics

Analytics:
Firebase Analytics

Version Control:
GitHub

Design:
Figma free plan

Testing:
Flutter test + manual APK testing

Distribution:
APK direct sharing first

This is the cleanest zero-cost setup.

10. Feature-to-Tech Mapping
Feature	Tech
Today timeline	Flutter custom UI
Routine builder	Flutter forms
Time range selection	Flutter time picker
Category system	SQLite table
Repeat routine	Local recurrence logic
Local reminders	Local notifications
Focus timer	Dart timer / ticker
Completion tracking	SQLite logs
Skip reason tracking	SQLite logs
Daily score	Local calculation
Weekly analytics	SQLite queries
Charts	fl_chart
Calendar heatmap	Custom Flutter calendar
Smart coach	Rule-based logic
Cloud sync later	Firestore
Login later	Firebase Auth
Push later	Firebase Cloud Messaging
11. Smart Coach Without Paid AI

You can create a smart system with rules.

A. Overplanning Detector

Logic:

total_planned_minutes > average_completed_minutes * 1.5

Message:

You planned 8 hours today, but your average completed routine time is 4.5 hours. Reduce today’s plan or convert some routines to mini versions.
B. Bad Time Detector

Logic:

routine completion rate at 10 PM < 40%
same category completion rate at 8 PM > 70%

Message:

You usually fail reading after 10 PM. Try moving reading to 8:30 PM.
C. Skip Reason Analysis

Logic:

most common skip reason = tired

Message:

Most missed routines are skipped because you feel tired. Use shorter night routines or move important tasks earlier.
D. Recovery Suggestion

Logic:

routine missed
current time before sleep
mini version exists

Message:

You missed your 60-minute reading block. Do the 10-minute mini version now to maintain consistency.
E. Routine Health Score

Formula:

routine_health =
completion_rate * 40
+ on_time_rate * 25
+ recovery_rate * 20
+ consistency_score * 15

This gives each routine a score out of 100.

12. Backend Decision: Firebase vs Supabase

For your specific app, I recommend:

Firebase first

Reason:

Easier with Flutter.
Free Spark plan is enough for MVP.
FCM is useful for notifications later.
Auth + Firestore + Analytics + Crashlytics are easy to integrate.
You do not need relational backend for MVP because the primary data can live locally.

Supabase is also good, especially if you want PostgreSQL, SQL queries, Row Level Security, and Edge Functions. Supabase has a free plan and provides Postgres database, Auth, APIs, Realtime, Functions, Storage, and Vector features, but for this routine app, Firebase is simpler for mobile-first MVP.

Use Supabase only if:

You want a web admin dashboard early.
You want SQL-first backend.
You want complex relational reporting in the cloud.
You are more comfortable designing database schemas than Firestore documents.
13. Free Admin/Web Dashboard Later

Later, you may want a web dashboard for:

User analytics
Routine templates
App settings
Feedback
Blog/landing page

Use:

Next.js
Tailwind CSS
shadcn/ui
Firebase Admin SDK only later
Vercel Hobby

Vercel’s Hobby plan is free for personal/small-scale apps, with included limits such as 1,000,000 function invocations and 50,000 web analytics events, but it is restricted to non-commercial personal use under fair-use guidelines.

For your actual SaaS/business product, Vercel Hobby may not be the right long-term commercial hosting plan. But for prototype/portfolio/MVP testing, it is fine.

14. Notification Architecture
MVP: Local Reminder
SQLite routine schedule
↓
Local notification scheduler
↓
Device notification
↓
User taps notification
↓
Open focus screen

No backend cost.

Later: Cloud Push
Firestore user reminder settings
↓
Backend scheduled job
↓
FCM push notification
↓
Device receives notification

But this later version needs a server/Cloud Function/cron system. Do not build this first if you want zero cost.

Expo’s push service also exists for React Native/Expo apps; its docs explain that Expo forwards notifications to FCM/APNs using an Expo push token. But since your recommended stack is Flutter, Firebase Cloud Messaging is the more natural future option.

15. Folder Structure

Use feature-first clean architecture:

lib/
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
│
├── core/
│   ├── constants/
│   ├── utils/
│   ├── services/
│   ├── notifications/
│   └── database/
│
├── features/
│   ├── today/
│   │   ├── presentation/
│   │   ├── application/
│   │   └── data/
│   │
│   ├── routines/
│   │   ├── presentation/
│   │   ├── application/
│   │   └── data/
│   │
│   ├── focus/
│   ├── calendar/
│   ├── analytics/
│   ├── coach/
│   ├── templates/
│   └── settings/
│
└── shared/
    ├── widgets/
    ├── models/
    └── extensions/

This will keep the app scalable.

16. Suggested Packages

Use packages like these:

dependencies:
  flutter:
    sdk: flutter

  flutter_riverpod:
  go_router:

  drift:
  sqlite3_flutter_libs:
  path_provider:
  path:

  shared_preferences:

  flutter_local_notifications:
  timezone:

  intl:
  uuid:
  equatable:

  fl_chart:
  table_calendar:

  firebase_core:
  firebase_auth:
  cloud_firestore:
  firebase_messaging:
  firebase_analytics:
  firebase_crashlytics:

For MVP, you can skip Firebase packages initially and add them later.

Start with:

flutter_riverpod
go_router
drift
sqlite3_flutter_libs
path_provider
shared_preferences
flutter_local_notifications
timezone
intl
uuid
fl_chart
table_calendar
17. MVP Build Order

Do not start with AI or cloud.

Build in this order:

Phase 1: Local Core
Create routine
Add category
Add start/end time
Repeat days
Show today timeline
Mark complete / skip / reschedule
Save logs locally
Phase 2: Reminder Engine
Reminder before start
Reminder at start
Late reminder
Recovery reminder
Daily review reminder
Phase 3: Focus Mode
Start routine
Timer
Pause/resume
End session
Add progress
Save actual duration
Phase 4: Analytics
Daily score
Weekly completion rate
Category progress
Best productive time
Most skipped routine
Skip reason chart
Phase 5: Smart Coach
Overplanning warning
Bad time detection
Mini version suggestion
Weekly improvement suggestion
Routine health score
Phase 6: Cloud Sync
Firebase Auth
Firestore backup
Restore data
Multi-device sync
18. Final Recommendation

Build the first version like this:

Flutter
+ Riverpod
+ Drift SQLite
+ Local Notifications
+ fl_chart
+ table_calendar
+ Rule-based Smart Coach

Add Firebase only after the offline app is solid.

Your MVP should be:

100% usable offline
No backend required
No paid AI required
No paid notification system required
No paid database required
No app-store publishing required at first

That is the most realistic completely free stack.