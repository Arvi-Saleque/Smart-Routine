import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      showBottomNavigation: false,
      actions: const [],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionHeader(
            title: 'App preferences',
            subtitle:
                'Settings storage will be connected with shared_preferences later.',
          ),
          SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle:
                'Local reminder controls will be added in the reminder phase.',
          ),
          SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Theme mode',
            subtitle: 'The app currently follows the system theme.',
          ),
          SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Data controls',
            subtitle:
                'Clear data actions will be added after local storage exists.',
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
      ),
    );
  }
}
