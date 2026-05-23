import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';

class RoutineDetailScreen extends StatelessWidget {
  const RoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Routine detail',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'Routine information',
            subtitle:
                'Health score, recent logs, and schedule details will appear here.',
          ),
          const SizedBox(height: 16),
          EmptyState(
            icon: Icons.insights_outlined,
            title: 'Detail screen ready',
            message: 'Route parameter received: $routineId',
            action: PrimaryButton(
              label: 'Edit routine',
              icon: Icons.edit_outlined,
              onPressed: () => context.go('/routine/$routineId/edit'),
            ),
          ),
        ],
      ),
    );
  }
}
