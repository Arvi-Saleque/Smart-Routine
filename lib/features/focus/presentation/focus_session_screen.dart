import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/routine_status.dart';
import '../../../shared/extensions/duration_extensions.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../routines/application/routine_providers.dart';
import '../../routines/data/routine_repository.dart';
import '../application/focus_providers.dart';
import '../data/focus_repository.dart';

class FocusSessionScreen extends ConsumerStatefulWidget {
  const FocusSessionScreen({
    super.key,
    required this.routineId,
    this.recoveryMode = false,
  });

  final String routineId;
  final bool recoveryMode;

  @override
  ConsumerState<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends ConsumerState<FocusSessionScreen> {
  final _noteController = TextEditingController();
  Timer? _timer;
  DateTime? _startedAt;
  DateTime? _runningSince;
  Duration _elapsedBeforeCurrentRun = Duration.zero;
  Duration _elapsed = Duration.zero;
  int _distractionCount = 0;
  _FocusTimerStatus _status = _FocusTimerStatus.idle;
  bool _saving = false;

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routine = ref.watch(routineDetailProvider(widget.routineId));

    return AppScaffold(
      title: 'Focus session',
      showBottomNavigation: false,
      body: routine.when(
        data: (detail) {
          if (detail == null) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Routine not found',
                  message: 'This routine may have been deleted.',
                ),
              ],
            );
          }
          return _buildFocusBody(context, detail);
        },
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load routine',
              message: '$error',
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildFocusBody(BuildContext context, RoutineDetail detail) {
    final plannedMinutes = widget.recoveryMode
        ? detail.routine.miniDurationMinutes
        : detail.routine.fullDurationMinutes;
    final plannedDuration = Duration(minutes: plannedMinutes);
    final progress = plannedDuration.inSeconds == 0
        ? 0.0
        : (_elapsed.inSeconds / plannedDuration.inSeconds).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: widget.recoveryMode
              ? '${detail.routine.title} mini recovery'
              : detail.routine.title,
          subtitle: detail.scheduleLabel,
          trailing: CategoryChip(
            label: detail.category.name,
            icon: categoryIconFromName(detail.category.iconName),
            color: Color(detail.category.colorValue),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  _formatElapsed(_elapsed),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Planned ${plannedDuration.compactLabel}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _primaryAction(detail),
                      icon: Icon(_primaryIcon),
                      label: Text(_primaryLabel),
                    ),
                    OutlinedButton.icon(
                      onPressed: _canPauseOrResume ? _pauseOrResume : null,
                      icon: Icon(
                        _status == _FocusTimerStatus.paused
                            ? Icons.play_arrow
                            : Icons.pause,
                      ),
                      label: Text(
                        _status == _FocusTimerStatus.paused
                            ? 'Resume'
                            : 'Pause',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _status == _FocusTimerStatus.idle
                          ? null
                          : () => setState(() => _distractionCount++),
                      icon: const Icon(Icons.notification_important_outlined),
                      label: const Text('Distracted'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session notes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'What did you finish or notice?',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.bolt_outlined),
                      label: Text('Goal: ${detail.goalLabel}'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.notification_important_outlined),
                      label: Text('Distractions: $_distractionCount'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _RecentFocusSessions(routineId: widget.routineId),
      ],
    );
  }

  VoidCallback? _primaryAction(RoutineDetail detail) {
    if (_saving) return null;
    return switch (_status) {
      _FocusTimerStatus.idle => _start,
      _FocusTimerStatus.running ||
      _FocusTimerStatus.paused => () => _finish(detail),
      _FocusTimerStatus.finished => null,
    };
  }

  IconData get _primaryIcon {
    return switch (_status) {
      _FocusTimerStatus.idle => Icons.play_arrow,
      _FocusTimerStatus.running || _FocusTimerStatus.paused => Icons.check,
      _FocusTimerStatus.finished => Icons.check_circle,
    };
  }

  String get _primaryLabel {
    if (_saving) return 'Saving...';
    return switch (_status) {
      _FocusTimerStatus.idle => 'Start',
      _FocusTimerStatus.running || _FocusTimerStatus.paused => 'Finish',
      _FocusTimerStatus.finished => 'Saved',
    };
  }

  bool get _canPauseOrResume {
    return _status == _FocusTimerStatus.running ||
        _status == _FocusTimerStatus.paused;
  }

  void _start() {
    setState(() {
      _startedAt = DateTime.now();
      _runningSince = _startedAt;
      _elapsedBeforeCurrentRun = Duration.zero;
      _elapsed = Duration.zero;
      _status = _FocusTimerStatus.running;
    });
    _startTicker();
  }

  void _pauseOrResume() {
    if (_status == _FocusTimerStatus.running) {
      _timer?.cancel();
      setState(() {
        _elapsed = _currentElapsed();
        _elapsedBeforeCurrentRun = _elapsed;
        _runningSince = null;
        _status = _FocusTimerStatus.paused;
      });
      return;
    }

    if (_status == _FocusTimerStatus.paused) {
      setState(() {
        _runningSince = DateTime.now();
        _status = _FocusTimerStatus.running;
      });
      _startTicker();
    }
  }

  Future<void> _finish(RoutineDetail detail) async {
    _timer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    final startedAt = _startedAt ?? DateTime.now();
    final endedAt = DateTime.now();
    final actualElapsed = _currentElapsed();

    setState(() => _saving = true);
    try {
      await ref
          .read(focusControllerProvider)
          .finishSession(
            FocusSessionDraft(
              routineDetail: detail,
              startedAt: startedAt,
              endedAt: endedAt,
              actualDuration: actualElapsed,
              plannedDurationMinutes: widget.recoveryMode
                  ? detail.routine.miniDurationMinutes
                  : detail.routine.fullDurationMinutes,
              distractionCount: _distractionCount,
              note: _noteController.text,
              completionStatus: widget.recoveryMode
                  ? RoutineStatus.recovered
                  : RoutineStatus.completed,
            ),
          );
      ref.invalidate(focusSessionsProvider(widget.routineId));
      if (!mounted) return;
      setState(() {
        _status = _FocusTimerStatus.finished;
        _saving = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Saved ${detail.routine.title} focus session.')),
      );
      context.go('/routine/${detail.routine.id}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _status = _FocusTimerStatus.paused;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save focus session: $error')),
      );
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _status != _FocusTimerStatus.running) return;
      setState(() => _elapsed = _currentElapsed());
    });
  }

  Duration _currentElapsed() {
    final runningSince = _runningSince;
    if (runningSince == null) return _elapsed;
    return _elapsedBeforeCurrentRun + DateTime.now().difference(runningSince);
  }

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _RecentFocusSessions extends ConsumerWidget {
  const _RecentFocusSessions({required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(focusSessionsProvider(routineId));

    return sessions.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.history_outlined,
            title: 'No focus sessions yet',
            message: 'Finished sessions for this routine will appear here.',
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent sessions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final session in items.take(3)) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(
                      Duration(
                        minutes: session.actualDurationMinutes,
                      ).compactLabel,
                    ),
                    subtitle: Text('Distractions: ${session.distractionCount}'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load sessions',
        message: '$error',
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

enum _FocusTimerStatus { idle, running, paused, finished }
