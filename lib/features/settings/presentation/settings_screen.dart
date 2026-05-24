import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_settings.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/settings_providers.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref
        .watch(themeModeProvider)
        .maybeWhen(data: (mode) => mode, orElse: () => ThemeMode.system);
    final reminderSettings = ref
        .watch(reminderSettingsProvider)
        .maybeWhen(
          data: (settings) => settings,
          orElse: () => const ReminderSettings(),
        );
    final startOfWeek = ref
        .watch(startOfWeekProvider)
        .maybeWhen(data: (value) => value, orElse: () => StartOfWeek.saturday);
    final controller = ref.read(settingsControllerProvider);

    return AppScaffold(
      title: 'Settings',
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          context.go('/');
        },
      ),
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
          _ThemeModeTile(value: themeMode, onChanged: controller.setThemeMode),
          const SizedBox(height: 12),
          _ReminderSettingsTile(
            settings: reminderSettings,
            onEnabledChanged: controller.setRemindersEnabled,
            onPreparationChanged: controller.setPreparationReminderMinutes,
            onLateChanged: controller.setLateReminderMinutes,
          ),
          const SizedBox(height: 12),
          _StartOfWeekTile(
            value: startOfWeek,
            onChanged: controller.setStartOfWeek,
          ),
          const SizedBox(height: 12),
          _ClearDataTile(onConfirmed: () => _clearData(context, ref)),
        ],
      ),
    );
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear local data?'),
          content: const Text(
            'This removes routines, schedules, logs, focus sessions, reminders, and daily scores from this device. App settings stay unchanged.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear data'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(settingsControllerProvider).clearAllData();
      ref.invalidate(themeModeProvider);
      ref.invalidate(reminderSettingsProvider);
      ref.invalidate(startOfWeekProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Local RoutineOS data cleared.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not clear local data: $error')),
      );
    }
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TileHeader(
              icon: Icons.dark_mode_outlined,
              title: 'Theme mode',
              subtitle: 'Choose how RoutineOS should appear.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_suggest_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.single),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSettingsTile extends StatelessWidget {
  const _ReminderSettingsTile({
    required this.settings,
    required this.onEnabledChanged,
    required this.onPreparationChanged,
    required this.onLateChanged,
  });

  final ReminderSettings settings;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onPreparationChanged;
  final ValueChanged<int> onLateChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                settings.remindersEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: const Text('Routine reminders'),
              subtitle: Text(
                settings.remindersEnabled
                    ? 'Local reminders are enabled.'
                    : 'All local routine reminders are paused.',
              ),
              value: settings.remindersEnabled,
              onChanged: onEnabledChanged,
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _MinutesInput(
                    label: 'Preparation',
                    value: settings.defaultPreparationReminderMinutes,
                    onSubmitted: onPreparationChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MinutesInput(
                    label: 'Late',
                    value: settings.defaultLateReminderMinutes,
                    onSubmitted: onLateChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MinutesInput extends StatefulWidget {
  const _MinutesInput({
    required this.label,
    required this.value,
    required this.onSubmitted,
  });

  final String label;
  final int value;
  final ValueChanged<int> onSubmitted;

  @override
  State<_MinutesInput> createState() => _MinutesInputState();
}

class _MinutesInputState extends State<_MinutesInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_saveOnBlur);
  }

  @override
  void didUpdateWidget(covariant _MinutesInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_saveOnBlur);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: '${widget.label} minutes',
        suffixText: 'min',
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onFieldSubmitted: (_) => _submit(),
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
    );
  }

  void _saveOnBlur() {
    if (!_focusNode.hasFocus) _submit();
  }

  void _submit() {
    final minutes = int.tryParse(_controller.text);
    if (minutes == null) return;
    widget.onSubmitted(minutes);
  }
}

class _StartOfWeekTile extends StatelessWidget {
  const _StartOfWeekTile({required this.value, required this.onChanged});

  final StartOfWeek value;
  final ValueChanged<StartOfWeek> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TileHeader(
              icon: Icons.calendar_month_outlined,
              title: 'Start of week',
              subtitle: 'Used by calendar views.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<StartOfWeek>(
              initialValue: value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Week starts on',
              ),
              items: [
                for (final option in StartOfWeek.values)
                  DropdownMenuItem(value: option, child: Text(option.label)),
              ],
              onChanged: (option) {
                if (option != null) onChanged(option);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearDataTile extends StatelessWidget {
  const _ClearDataTile({required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(Icons.delete_outline, color: colorScheme.error),
        title: const Text('Clear all local data'),
        subtitle: const Text(
          'Remove routines, logs, focus sessions, reminders, and scores.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onConfirmed,
      ),
    );
  }
}

class _TileHeader extends StatelessWidget {
  const _TileHeader({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}
