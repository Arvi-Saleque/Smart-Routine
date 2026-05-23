import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';

class FocusSessionScreen extends StatelessWidget {
  const FocusSessionScreen({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Focus session',
      showBottomNavigation: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'Focus mode',
            subtitle:
                'Timer controls will be connected after routine logs exist.',
          ),
          const SizedBox(height: 16),
          EmptyState(
            icon: Icons.timer_outlined,
            title: 'Focus shell ready',
            message: 'Route parameter received: $routineId',
            action: const PrimaryButton(
              label: 'Timer coming next',
              onPressed: null,
            ),
          ),
        ],
      ),
    );
  }
}
