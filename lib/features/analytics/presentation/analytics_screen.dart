import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: 'Analytics', body: _AnalyticsBody());
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SectionHeader(
          title: 'Productivity analytics',
          subtitle: 'Charts will use local routine logs and focus sessions.',
        ),
        SizedBox(height: 16),
        EmptyState(
          icon: Icons.query_stats_outlined,
          title: 'No analytics yet',
          message:
              'Daily score, category progress, and focus minutes will appear after tracking.',
        ),
      ],
    );
  }
}
