import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/routine_status.dart';
import '../../../core/enums/skip_reason.dart';
import '../../../shared/extensions/date_time_extensions.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/routine_card.dart';
import '../../../shared/widgets/score_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/today_providers.dart';
import '../data/today_repository.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final timeline = ref.watch(todayTimelineProvider);

    return AppScaffold(
      title: 'RoutineOS',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/routine/create'),
        icon: const Icon(Icons.add),
        label: const Text('Routine'),
      ),
      body: timeline.when(
        data: (data) => _TodayBody(today: today, timeline: data),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load today',
              message: '$error',
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TodayBody extends StatelessWidget {
  const _TodayBody({required this.today, required this.timeline});

  final DateTime today;
  final TodayTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final active = timeline.activeEntry;
    final next = timeline.nextEntry;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          today.weekdayMonthDay,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ScoreCard(
          title: 'Daily score',
          score: timeline.dailyScore?.score,
          message: timeline.scoreMessage,
        ),
        const SizedBox(height: 12),
        ScoreCard(
          title: 'Daily progress',
          score: timeline.progressScore,
          message: timeline.progressMessage,
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Current routine',
          subtitle: 'The active time block is based on the current time.',
        ),
        const SizedBox(height: 12),
        if (active == null)
          const EmptyState(
            icon: Icons.play_circle_outline,
            title: 'No active routine',
            message: 'You do not have a routine scheduled for this moment.',
          )
        else
          _TimelineRoutineCard(entry: active, highlight: true),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Next routine',
          subtitle: 'The next upcoming time block for today.',
        ),
        const SizedBox(height: 12),
        if (next == null)
          const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'No upcoming routine',
            message:
                'All scheduled routines for today are either done or past.',
          )
        else
          _TimelineRoutineCard(entry: next),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Today timeline',
          subtitle: 'Scheduled routines in chronological order.',
        ),
        const SizedBox(height: 12),
        if (timeline.entries.isEmpty)
          EmptyState(
            icon: Icons.timeline_outlined,
            title: 'No routines planned',
            message: 'The timeline is ready for your first routine block.',
            action: PrimaryButton(
              label: 'Create routine',
              icon: Icons.add,
              onPressed: () => context.go('/routine/create'),
            ),
          )
        else
          for (final entry in timeline.entries) ...[
            _TimelineRoutineCard(entry: entry),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _TimelineRoutineCard extends ConsumerWidget {
  const _TimelineRoutineCard({required this.entry, this.highlight = false});

  final TodayTimelineEntry entry;
  final bool highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = entry.detail;
    final status = entry.status;
    final isFinished =
        status == RoutineStatus.completed ||
        status == RoutineStatus.skipped ||
        status == RoutineStatus.recovered ||
        status == RoutineStatus.moved;
    final isMissed = status == RoutineStatus.missed;

    return RoutineCard(
      title: detail.routine.title,
      timeRange: entry.timeRangeLabel,
      status: status,
      category: CategoryChip(
        label: detail.category.name,
        icon: categoryIconFromName(detail.category.iconName),
        color: Color(detail.category.colorValue),
      ),
      goal: detail.goalLabel,
      onStart: isFinished
          ? null
          : () => context.go('/focus/${detail.routine.id}'),
      onComplete: isFinished ? null : () => _markCompleted(context, ref),
      onSkip: isFinished ? null : () => _markSkipped(context, ref),
      extraActions: isMissed
          ? [
              OutlinedButton.icon(
                onPressed: () =>
                    context.go('/focus/${detail.routine.id}?mode=mini'),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Mini'),
              ),
              OutlinedButton.icon(
                onPressed: () => _rescheduleToday(context, ref),
                icon: const Icon(Icons.schedule),
                label: const Text('Later'),
              ),
              TextButton.icon(
                onPressed: () => _moveToTomorrow(context, ref),
                icon: const Icon(Icons.event_repeat),
                label: const Text('Tomorrow'),
              ),
            ]
          : const [],
    );
  }

  Future<void> _markCompleted(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(todayControllerProvider).markCompleted(entry);
      ref.invalidate(todayTimelineProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('${entry.detail.routine.title} completed.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not complete routine: $error')),
      );
    }
  }

  Future<void> _markSkipped(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<SkipReason>(
      context: context,
      builder: (context) => const _SkipReasonDialog(),
    );
    if (reason == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(todayControllerProvider).markSkipped(entry, reason);
      ref.invalidate(todayTimelineProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('${entry.detail.routine.title} skipped.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not skip routine: $error')),
      );
    }
  }

  Future<void> _rescheduleToday(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(todayControllerProvider).rescheduleLaterToday(entry);
      ref.invalidate(todayTimelineProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${entry.detail.routine.title} moved later today.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not reschedule routine: $error')),
      );
    }
  }

  Future<void> _moveToTomorrow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(todayControllerProvider).moveToTomorrow(entry);
      ref.invalidate(todayTimelineProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${entry.detail.routine.title} moved to tomorrow.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not move routine: $error')),
      );
    }
  }
}

class _SkipReasonDialog extends StatelessWidget {
  const _SkipReasonDialog();

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Why skip this routine?'),
      children: [
        for (final reason in SkipReason.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(reason),
            child: Text(reason.label),
          ),
      ],
    );
  }
}
