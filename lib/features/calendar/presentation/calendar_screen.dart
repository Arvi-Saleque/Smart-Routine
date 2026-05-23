import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: 'Calendar', body: _CalendarBody());
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SectionHeader(
          title: 'Monthly view',
          subtitle:
              'Routine history and selected-day summaries will be shown here.',
        ),
        SizedBox(height: 16),
        EmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'Calendar shell ready',
          message:
              'The table_calendar integration will be connected with real logs later.',
        ),
      ],
    );
  }
}
