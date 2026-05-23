import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersEnabled = ref.watch(remindersEnabledProvider);

    return AppScaffold(
      title: 'Settings',
      showBottomNavigation: false,
      actions: const [],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'App preferences',
            subtitle: 'Control local app behavior stored on this device.',
          ),
          const SizedBox(height: 16),
          _NotificationSwitchTile(
            enabled: remindersEnabled.maybeWhen(
              data: (enabled) => enabled,
              orElse: () => true,
            ),
            loading: remindersEnabled.isLoading,
            onChanged: (enabled) =>
                _setReminderPreference(ref: ref, enabled: enabled),
          ),
          const SizedBox(height: 12),
          const _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Reminder types',
            subtitle: 'Preparation, start, late, and recovery reminders.',
          ),
          const SizedBox(height: 12),
          const _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Theme mode',
            subtitle: 'The app currently follows the system theme.',
          ),
          const SizedBox(height: 12),
          const _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Data controls',
            subtitle:
                'Clear data actions will be added after local storage exists.',
          ),
        ],
      ),
    );
  }

  Future<void> _setReminderPreference({
    required WidgetRef ref,
    required bool enabled,
  }) async {
    await ref
        .read(notificationSettingsStoreProvider)
        .setRemindersEnabled(enabled);

    final scheduler = ref.read(notificationSchedulerProvider);
    if (enabled) {
      await scheduler.initializeAndReschedule();
    } else {
      await scheduler.cancelAllRoutineReminders();
    }
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.enabled,
    required this.loading,
    required this.onChanged,
  });

  final bool enabled;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: SwitchListTile(
        secondary: Icon(
          enabled ? Icons.notifications_active : Icons.notifications_off,
          color: colorScheme.primary,
        ),
        title: Text('Routine reminders', style: theme.textTheme.titleMedium),
        subtitle: Text(
          loading
              ? 'Loading reminder preference...'
              : enabled
              ? 'Local reminders are enabled for routines that allow them.'
              : 'All local routine reminders are paused.',
        ),
        value: enabled,
        onChanged: loading ? null : onChanged,
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
