import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';

class RoutineListScreen extends StatelessWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Routines',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/routine/create'),
        tooltip: 'Add routine',
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'All routines',
            subtitle:
                'Manage fixed-time, flexible, duration, and count habits.',
          ),
          const SizedBox(height: 16),
          EmptyState(
            icon: Icons.checklist_outlined,
            title: 'Build your first routine',
            message:
                'Routine cards will appear here after the local database phase.',
            action: PrimaryButton(
              label: 'Add routine',
              icon: Icons.add,
              onPressed: () => context.go('/routine/create'),
            ),
          ),
        ],
      ),
    );
  }
}
