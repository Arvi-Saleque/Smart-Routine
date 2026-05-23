import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/extensions/date_time_extensions.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/score_card.dart';
import '../../../shared/widgets/section_header.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return AppScaffold(
      title: 'RoutineOS',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/routine/create'),
        icon: const Icon(Icons.add),
        label: const Text('Routine'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            today.weekdayMonthDay,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          const ScoreCard(
            title: 'Daily score',
            message: 'Your score will appear after routines are tracked.',
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Current routine',
            subtitle: 'The active time block will be highlighted here.',
          ),
          const SizedBox(height: 12),
          EmptyState(
            icon: Icons.play_circle_outline,
            title: 'No active routine',
            message: 'Create a fixed-time routine to see what needs focus now.',
            action: PrimaryButton(
              label: 'Create routine',
              icon: Icons.add,
              onPressed: () => context.go('/routine/create'),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Today timeline',
            subtitle: 'Scheduled routines will appear in chronological order.',
          ),
          const SizedBox(height: 12),
          const EmptyState(
            icon: Icons.timeline_outlined,
            title: 'No routines planned',
            message: 'The timeline is ready for your first routine block.',
          ),
        ],
      ),
    );
  }
}
