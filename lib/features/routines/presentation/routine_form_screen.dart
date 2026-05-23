import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';

class RoutineFormScreen extends StatelessWidget {
  const RoutineFormScreen({super.key, this.routineId});

  final String? routineId;

  bool get isEditing => routineId != null;

  @override
  Widget build(BuildContext context) {
    final title = isEditing ? 'Edit routine' : 'Create routine';

    return AppScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(
            title: title,
            subtitle: isEditing
                ? 'The edit form will load saved routine details here.'
                : 'The full routine builder form will be implemented after the database foundation.',
          ),
          const SizedBox(height: 16),
          EmptyState(
            icon: Icons.edit_calendar_outlined,
            title: isEditing
                ? 'Edit form placeholder'
                : 'Routine builder placeholder',
            message:
                'This screen is wired into routing and ready for form fields, validation, and persistence.',
            action: PrimaryButton(
              label: isEditing ? 'Save changes later' : 'Create later',
              onPressed: null,
            ),
          ),
        ],
      ),
    );
  }
}
