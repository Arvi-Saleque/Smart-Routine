# Agent Instructions for Smart-Routine

## Primary Rule

Always follow this order before making implementation decisions:

1. Read `plan.md`.
2. Read `memory.md`.
3. Inspect the current repo state.
4. Make the smallest useful implementation step.
5. Update `memory.md`.
6. Commit with a clear message.
7. Push to the remote repository.

## Required Working Files

### `plan.md`

`plan.md` is the source of truth for the product, architecture, phases, feature order, and technical direction.

Do not skip ahead into later phases unless the user explicitly asks.

### `memory.md`

`memory.md` must be maintained after every meaningful work portion.

It should include:

- What was completed
- What files were changed
- What commands were run
- Any known issues
- The next recommended step

Keep it concise but useful enough for another agent to continue without confusion.

## Git and Commit Rules

- Commit after each meaningful portion of work.
- Use proper commit messages.
- Push after every commit when network and credentials allow it.
- Do not make one huge commit for unrelated phases.
- Do not commit broken code unless the user explicitly asks to save work in progress.
- Run relevant checks before committing.

Recommended commit message style:

- `docs: add project plan and agent instructions`
- `chore: scaffold Flutter project`
- `feat: add app routing shell`
- `feat: add routine database tables`
- `fix: resolve analyzer issues`

## Implementation Order

Follow the implementation phases in `plan.md`:

1. Project setup and architecture
2. Drift database foundation
3. Routine CRUD
4. Today timeline
5. Focus session
6. Local reminders
7. Recovery system
8. Daily score
9. Calendar
10. Analytics
11. Smart coach
12. Polish and release prep

## App Constraints

- MVP must work offline.
- MVP must not require Firebase, Supabase, paid AI APIs, paid backend, paid database, paid server, or paid notification service.
- Use local SQLite through Drift for app data.
- Use `shared_preferences` only for lightweight settings.
- Use local notifications for reminders.
- Keep business logic out of widgets.
- Keep UI, state, repositories, database, and services separated.

## Code Quality Rules

- Keep code readable and production-style.
- Avoid giant widgets.
- Use reusable shared widgets.
- Avoid fake business logic when real local logic is reasonable.
- Do not leave TODO-only files.
- Do not leave broken imports.
- Run `flutter analyze` after major coding portions.
- Fix analyzer errors before committing.

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

Avoid childish UI, clutter, and placeholder pages that feel unfinished.

## Safety Rules

- Never delete user files unless explicitly requested.
- Never reset or rewrite Git history unless explicitly requested.
- Never add secrets, API keys, signing keys, or local environment files to Git.
- Check `.gitignore` before adding generated files.
- If a push fails because of authentication or remote permissions, report the exact issue and leave the local commit intact.

## Handoff Rule

Before ending a work session, make sure:

- `memory.md` is updated.
- Git status is checked.
- The latest completed portion is committed.
- The commit is pushed when possible.
- The final response clearly states what changed, what was verified, and what remains next.

