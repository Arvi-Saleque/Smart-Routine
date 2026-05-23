import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/routine_status.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../routines/data/routine_repository.dart';
import '../../today/data/daily_score_repository.dart';

class FocusRepository {
  FocusRepository(
    this._database, {
    Uuid? uuid,
    DailyScoreRepository? scoreRepository,
  }) : _uuid = uuid ?? const Uuid(),
       _scoreRepository = scoreRepository ?? DailyScoreRepository(_database);

  final AppDatabase _database;
  final Uuid _uuid;
  final DailyScoreRepository _scoreRepository;

  Future<FocusSaveResult> finishSession(FocusSessionDraft draft) async {
    final dateKey = DateTimeUtils.dateKey(draft.startedAt);
    final detail = draft.routineDetail;
    final routine = detail.routine;
    final schedule = detail.schedule;
    final now = draft.endedAt;
    final actualMinutes = draft.actualDuration.inMinutes <= 0
        ? 1
        : draft.actualDuration.inMinutes;

    final result = await _database.transaction(() async {
      final existingLog =
          await (_database.select(_database.routineLogs)
                ..where(
                  (table) =>
                      table.routineId.equals(routine.id) &
                      table.date.equals(dateKey),
                )
                ..limit(1))
              .getSingleOrNull();

      final routineLogId = existingLog?.id ?? _uuid.v4();
      final plannedStart =
          schedule?.startTimeMinutes ??
          draft.startedAt.hour * 60 + draft.startedAt.minute;
      final plannedEnd =
          schedule?.endTimeMinutes ??
          plannedStart + draft.plannedDurationMinutes;

      if (existingLog == null) {
        await _database
            .into(_database.routineLogs)
            .insert(
              RoutineLogsCompanion.insert(
                id: routineLogId,
                routineId: routine.id,
                date: dateKey,
                status: draft.completionStatus.name,
                plannedStartTimeMinutes: plannedStart,
                plannedEndTimeMinutes: plannedEnd,
                actualStartAt: Value(draft.startedAt),
                actualEndAt: Value(now),
                actualDurationMinutes: Value(actualMinutes),
                completionValue: Value(actualMinutes.toDouble()),
                note: Value(_nullableText(draft.note)),
                createdAt: draft.startedAt,
                updatedAt: now,
              ),
            );
      } else {
        await (_database.update(
          _database.routineLogs,
        )..where((table) => table.id.equals(existingLog.id))).write(
          RoutineLogsCompanion(
            status: Value(draft.completionStatus.name),
            actualStartAt: Value(draft.startedAt),
            actualEndAt: Value(now),
            actualDurationMinutes: Value(actualMinutes),
            completionValue: Value(actualMinutes.toDouble()),
            note: Value(_nullableText(draft.note)),
            updatedAt: Value(now),
          ),
        );
      }

      final focusSessionId = _uuid.v4();
      await _database
          .into(_database.focusSessions)
          .insert(
            FocusSessionsCompanion.insert(
              id: focusSessionId,
              routineId: routine.id,
              routineLogId: Value(routineLogId),
              startedAt: draft.startedAt,
              endedAt: Value(now),
              plannedDurationMinutes: draft.plannedDurationMinutes,
              actualDurationMinutes: actualMinutes,
              distractionCount: Value(draft.distractionCount),
              note: Value(_nullableText(draft.note)),
              createdAt: now,
            ),
          );

      return FocusSaveResult(
        focusSessionId: focusSessionId,
        routineLogId: routineLogId,
        actualDurationMinutes: actualMinutes,
      );
    });

    await _scoreRepository.calculateAndSaveForDate(
      draft.startedAt,
      now: draft.endedAt,
    );

    return result;
  }

  Stream<List<FocusSession>> watchSessionsForRoutine(String routineId) {
    final query = _database.select(_database.focusSessions)
      ..where((table) => table.routineId.equals(routineId))
      ..orderBy([(table) => OrderingTerm.desc(table.startedAt)]);
    return query.watch();
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}

class FocusSessionDraft {
  const FocusSessionDraft({
    required this.routineDetail,
    required this.startedAt,
    required this.endedAt,
    required this.actualDuration,
    required this.plannedDurationMinutes,
    required this.distractionCount,
    required this.note,
    this.completionStatus = RoutineStatus.completed,
  });

  final RoutineDetail routineDetail;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration actualDuration;
  final int plannedDurationMinutes;
  final int distractionCount;
  final String note;
  final RoutineStatus completionStatus;
}

class FocusSaveResult {
  const FocusSaveResult({
    required this.focusSessionId,
    required this.routineLogId,
    required this.actualDurationMinutes,
  });

  final String focusSessionId;
  final String routineLogId;
  final int actualDurationMinutes;
}
