import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/difficulty_level.dart';
import '../../../core/enums/goal_type.dart';
import '../../../core/enums/priority_level.dart';
import '../../../core/enums/routine_type.dart';
import '../../../shared/extensions/duration_extensions.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/routine_providers.dart';
import '../data/routine_repository.dart';

class RoutineDetailScreen extends ConsumerWidget {
  const RoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(routineDetailProvider(routineId));

    return AppScaffold(
      title: 'Activity Details',
      body: detail.when(
        data: (routineDetail) {
          if (routineDetail == null) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Activity not found',
                  message: 'This activity may have been deleted.',
                ),
              ],
            );
          }
          return _RoutineDetailBody(detail: routineDetail);
        },
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load activity',
              message: '$error',
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _RoutineDetailBody extends ConsumerWidget {
  const _RoutineDetailBody({required this.detail});

  final RoutineDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = detail.routine;
    final categoryColor = Color(detail.category.colorValue);
    final repository = ref.read(routineRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: routine.title,
          subtitle: routine.description ?? 'No description added.',
          trailing: IconButton(
            tooltip: 'Edit activity',
            onPressed: () => context.go('/routine/${routine.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CategoryChip(
              label: detail.category.name,
              icon: categoryIconFromName(detail.category.iconName),
              color: categoryColor,
            ),
            Chip(
              avatar: Icon(routine.isActive ? Icons.play_arrow : Icons.pause),
              label: Text(routine.isActive ? 'Active' : 'Paused'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Schedule',
          rows: {
            'Time range': detail.scheduleLabel,
            'Repeat': detail.repeatLabel,
            'Reminder': routine.reminderEnabled ? 'Enabled' : 'Disabled',
          },
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Goal',
          rows: {
            'Tracking': _trackingLabel(
              GoalType.values.byName(routine.goalType),
            ),
            'Target': detail.goalLabel,
            'Activity type': RoutineType.values
                .byName(routine.routineType)
                .label,
            'Priority': PriorityLevel.values.byName(routine.priority).label,
            'Effort Level': DifficultyLevel.values
                .byName(routine.difficulty)
                .label,
          },
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Recovery',
          rows: {
            'Full': Duration(minutes: routine.fullDurationMinutes).compactLabel,
            'Medium': Duration(
              minutes: routine.mediumDurationMinutes,
            ).compactLabel,
            'Mini': Duration(minutes: routine.miniDurationMinutes).compactLabel,
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    repository.setRoutineActive(routine.id, !routine.isActive),
                icon: Icon(routine.isActive ? Icons.pause : Icons.play_arrow),
                label: Text(routine.isActive ? 'Pause' : 'Activate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.go('/focus/${routine.id}'),
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Focus'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _confirmDelete(context, ref),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete activity'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete activity?'),
          content: const Text(
            'This removes the activity and its local schedule data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(routineRepositoryProvider).deleteRoutine(detail.routine.id);
    if (context.mounted) context.go('/routines');
  }
}

String _trackingLabel(GoalType type) {
  return switch (type) {
    GoalType.simpleCheck => 'Just mark as done',
    GoalType.duration => 'Track time',
    GoalType.quantity => 'Track quantity',
    GoalType.count => 'Track count',
  };
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final entry in rows.entries) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
