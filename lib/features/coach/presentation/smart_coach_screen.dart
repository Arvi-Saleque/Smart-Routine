import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';

class SmartCoachScreen extends StatelessWidget {
  const SmartCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: 'Smart Coach', body: _SmartCoachBody());
  }
}

class _SmartCoachBody extends StatelessWidget {
  const _SmartCoachBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SectionHeader(
          title: 'Rule-based coaching',
          subtitle: 'Insights will be generated locally without paid AI APIs.',
        ),
        SizedBox(height: 16),
        EmptyState(
          icon: Icons.lightbulb_outline,
          title: 'Coach is waiting for data',
          message:
              'Overplanning, weak category, recovery, and streak insights will appear here.',
        ),
      ],
    );
  }
}
