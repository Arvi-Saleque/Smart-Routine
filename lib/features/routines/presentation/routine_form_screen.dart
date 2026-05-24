import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/difficulty_level.dart';
import '../../../core/enums/goal_type.dart';
import '../../../core/enums/priority_level.dart';
import '../../../core/enums/routine_type.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/routine_providers.dart';
import '../data/routine_repository.dart';

class RoutineFormScreen extends ConsumerStatefulWidget {
  const RoutineFormScreen({super.key, this.routineId});

  final String? routineId;

  bool get isEditing => routineId != null;

  @override
  ConsumerState<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends ConsumerState<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _fullDurationController = TextEditingController(text: '60');
  final _mediumDurationController = TextEditingController(text: '30');
  final _miniDurationController = TextEditingController(text: '10');

  String? _categoryId;
  RoutineType _routineType = RoutineType.fixedTime;
  GoalType _goalType = GoalType.duration;
  PriorityLevel _priority = PriorityLevel.medium;
  DifficultyLevel _difficulty = DifficultyLevel.normal;
  String _targetUnit = 'minutes';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  Set<int> _repeatDays = {1, 2, 3, 4, 5, 6, 7};
  _RepeatOption _repeatOption = _RepeatOption.everyDay;
  String? _specificDate;
  bool _reminderEnabled = true;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    _fullDurationController.dispose();
    _mediumDurationController.dispose();
    _miniDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit routine' : 'Create routine';
    final categories = ref.watch(categoriesProvider);
    final existingRoutine = widget.routineId == null
        ? null
        : ref.watch(routineDetailProvider(widget.routineId!));

    return AppScaffold(
      title: title,
      showBottomNavigation: false,
      body: categories.when(
        data: (categoryItems) {
          if (categoryItems.isNotEmpty && _categoryId == null) {
            _categoryId = categoryItems.first.id;
          }

          if (existingRoutine == null) {
            return _buildForm(context, categoryItems);
          }

          return existingRoutine.when(
            data: (detail) {
              if (detail == null) {
                return const _MissingRoutine();
              }
              _initializeFromDetail(detail);
              return _buildForm(context, categoryItems);
            },
            error: (error, _) => _FormError(message: '$error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          );
        },
        error: (error, _) => _FormError(message: '$error'),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Category> categories) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(
            title: widget.isEditing ? 'Tune this routine' : 'Build a routine',
            subtitle:
                'Save the time block, goal, repeat days, and recovery versions.',
          ),
          const SizedBox(height: 16),
          _BasicInfoSection(
            titleController: _titleController,
            descriptionController: _descriptionController,
            categories: categories,
            categoryId: _categoryId,
            onCategoryChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 12),
          _ScheduleSection(
            routineType: _routineType,
            startTime: _startTime,
            endTime: _endTime,
            repeatOption: _repeatOption,
            repeatDays: _repeatDays,
            onRoutineTypeChanged: (value) =>
                setState(() => _routineType = value),
            onPickStart: () => _pickTime(isStart: true),
            onPickEnd: () => _pickTime(isStart: false),
            onRepeatOptionChanged: _setRepeatOption,
            onRepeatDayChanged: _setRepeatDay,
          ),
          const SizedBox(height: 12),
          _GoalSection(
            goalType: _goalType,
            targetValueController: _targetValueController,
            targetUnit: _targetUnit,
            priority: _priority,
            difficulty: _difficulty,
            onGoalTypeChanged: (value) => setState(() {
              _goalType = value;
              if (value == GoalType.simpleCheck) {
                _targetValueController.clear();
              }
            }),
            onTargetUnitChanged: (value) => setState(() => _targetUnit = value),
            onPriorityChanged: (value) => setState(() => _priority = value),
            onDifficultyChanged: (value) => setState(() => _difficulty = value),
          ),
          const SizedBox(height: 12),
          _RecoveryVersionsSection(
            fullDurationController: _fullDurationController,
            mediumDurationController: _mediumDurationController,
            miniDurationController: _miniDurationController,
          ),
          const SizedBox(height: 12),
          _ReminderSection(
            routineType: _routineType,
            reminderEnabled: _reminderEnabled,
            onChanged: (value) => setState(() => _reminderEnabled = value),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _saveRoutine,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(widget.isEditing ? 'Save changes' : 'Create routine'),
          ),
        ],
      ),
    );
  }

  void _initializeFromDetail(RoutineDetail detail) {
    if (_initialized) return;
    final data = RoutineFormData.fromDetail(detail);
    _titleController.text = data.title;
    _descriptionController.text = data.description ?? '';
    _targetValueController.text = data.targetValue == null
        ? ''
        : data.targetValue!.toString();
    _targetUnit = _stableTargetUnit(data.targetUnit);
    _fullDurationController.text = data.fullDurationMinutes.toString();
    _mediumDurationController.text = data.mediumDurationMinutes.toString();
    _miniDurationController.text = data.miniDurationMinutes.toString();
    _categoryId = data.categoryId;
    _routineType = data.routineType;
    _goalType = data.goalType;
    _priority = data.priority;
    _difficulty = data.difficulty;
    _startTime = DateTimeUtils.minutesToTimeOfDay(data.startTimeMinutes);
    _endTime = DateTimeUtils.minutesToTimeOfDay(data.endTimeMinutes);
    _repeatDays = {...data.repeatDays};
    _specificDate = data.specificDate;
    _repeatOption = _repeatOptionFromData(data);
    _reminderEnabled = data.reminderEnabled;
    _initialized = true;
  }

  void _setRepeatOption(_RepeatOption option) {
    setState(() {
      _repeatOption = option;
      _specificDate = option == _RepeatOption.todayOnly
          ? DateTimeUtils.dateKey(DateTime.now())
          : null;
      if (option != _RepeatOption.customDays) {
        _repeatDays = option.repeatDays;
      }
    });
  }

  void _setRepeatDay(int weekday, bool selected) {
    setState(() {
      _repeatOption = _RepeatOption.customDays;
      _specificDate = null;
      if (selected) {
        _repeatDays.add(weekday);
      } else {
        _repeatDays.remove(weekday);
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  Future<void> _saveRoutine() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = DateTimeUtils.timeOfDayToMinutes(_startTime);
    final endMinutes = DateTimeUtils.timeOfDayToMinutes(_endTime);
    final data = _formData(startMinutes: startMinutes, endMinutes: endMinutes);

    try {
      data.validate();
    } on RoutineFormValidationException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(routineRepositoryProvider);
      final routineId = widget.routineId;
      if (routineId == null) {
        final createdId = await repository.createRoutine(data);
        if (mounted) context.go('/routine/$createdId');
      } else {
        await repository.updateRoutine(routineId, data);
        if (mounted) context.go('/routine/$routineId');
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  RoutineFormData _formData({
    required int startMinutes,
    required int endMinutes,
  }) {
    final targetText = _targetValueController.text.trim();
    final repeatDays = _repeatOption.repeatDays.isEmpty
        ? _repeatDays
        : _repeatOption.repeatDays;
    final specificDate = _repeatOption == _RepeatOption.todayOnly
        ? _specificDate ?? DateTimeUtils.dateKey(DateTime.now())
        : null;
    return RoutineFormData(
      title: _titleController.text,
      description: _descriptionController.text,
      categoryId: _categoryId ?? '',
      routineType: _routineType,
      goalType: _goalType,
      targetValue: targetText.isEmpty ? null : double.tryParse(targetText),
      targetUnit: _goalType == GoalType.simpleCheck ? null : _targetUnit,
      priority: _priority,
      difficulty: _difficulty,
      startTimeMinutes: startMinutes,
      endTimeMinutes: endMinutes,
      repeatDays: specificDate == null ? repeatDays : const {},
      specificDate: specificDate,
      fullDurationMinutes: int.tryParse(_fullDurationController.text) ?? 0,
      mediumDurationMinutes: int.tryParse(_mediumDurationController.text) ?? 0,
      miniDurationMinutes: int.tryParse(_miniDurationController.text) ?? 0,
      reminderEnabled: _reminderEnabled,
      timezone: DateTime.now().timeZoneName,
    );
  }
}

_RepeatOption _repeatOptionFromData(RoutineFormData data) {
  if (data.specificDate != null) return _RepeatOption.todayOnly;
  for (final option in _RepeatOption.values) {
    if (option == _RepeatOption.todayOnly ||
        option == _RepeatOption.customDays) {
      continue;
    }
    if (_setEquals(data.repeatDays, option.repeatDays)) return option;
  }
  return _RepeatOption.customDays;
}

bool _setEquals(Set<int> left, Set<int> right) {
  return left.length == right.length && left.containsAll(right);
}

String? _validateTargetValue(GoalType goalType, String? value) {
  final trimmed = value?.trim() ?? '';
  if (goalType == GoalType.simpleCheck) return null;
  if (trimmed.isEmpty) return 'Target value is required';
  return _validateOptionalPositiveNumber(value);
}

String? _validateOptionalPositiveNumber(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final parsed = double.tryParse(trimmed);
  if (parsed == null || parsed <= 0) return 'Use a positive number';
  return null;
}

String _stableTargetUnit(String? value) {
  if (value != null && _targetUnits.contains(value)) return value;
  return 'minutes';
}

class _BasicInfoSection extends StatelessWidget {
  const _BasicInfoSection({
    required this.titleController,
    required this.descriptionController,
    required this.categories,
    required this.categoryId,
    required this.onCategoryChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final List<Category> categories;
  final String? categoryId;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final stableCategoryId =
        categories.any((category) => category.id == categoryId)
        ? categoryId
        : null;

    return _FormCard(
      title: 'Basic info',
      children: [
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Title'),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(labelText: 'Description'),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: stableCategoryId,
          decoration: const InputDecoration(labelText: 'Category'),
          items: categories
              .map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(
                        categoryIconFromName(category.iconName),
                        color: Color(category.colorValue),
                      ),
                      const SizedBox(width: 10),
                      Text(category.name),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onCategoryChanged,
          validator: (value) => value == null ? 'Category is required' : null,
        ),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.routineType,
    required this.startTime,
    required this.endTime,
    required this.repeatOption,
    required this.repeatDays,
    required this.onRoutineTypeChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onRepeatOptionChanged,
    required this.onRepeatDayChanged,
  });

  final RoutineType routineType;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final _RepeatOption repeatOption;
  final Set<int> repeatDays;
  final ValueChanged<RoutineType> onRoutineTypeChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<_RepeatOption> onRepeatOptionChanged;
  final void Function(int weekday, bool selected) onRepeatDayChanged;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Schedule',
      children: [
        _EnumDropdown<RoutineType>(
          label: 'Routine type',
          value: routineType,
          values: RoutineType.values,
          labelFor: (type) => type.label,
          onChanged: onRoutineTypeChanged,
        ),
        if (routineType != RoutineType.fixedTime) ...[
          const SizedBox(height: 12),
          const _WarningPanel(
            icon: Icons.notifications_paused_outlined,
            message:
                'MVP reminder scheduling only supports fixed-time routines.',
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TimeButton(
                label: 'Start',
                time: startTime,
                onTap: onPickStart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeButton(label: 'End', time: endTime, onTap: onPickEnd),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _InfoPanel(
          icon: Icons.repeat,
          message:
              'Repeating routines automatically appear on future selected days. Today-only routines appear once.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<_RepeatOption>(
          initialValue: repeatOption,
          decoration: const InputDecoration(labelText: 'Repeat'),
          items: _RepeatOption.values
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (option) {
            if (option != null) onRepeatOptionChanged(option);
          },
        ),
        if (repeatOption == _RepeatOption.customDays) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final day in DateTimeUtils.weekdayShortLabels.entries)
                FilterChip(
                  selected: repeatDays.contains(day.key),
                  label: Text(day.value),
                  onSelected: (selected) =>
                      onRepeatDayChanged(day.key, selected),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GoalSection extends StatelessWidget {
  const _GoalSection({
    required this.goalType,
    required this.targetValueController,
    required this.targetUnit,
    required this.priority,
    required this.difficulty,
    required this.onGoalTypeChanged,
    required this.onTargetUnitChanged,
    required this.onPriorityChanged,
    required this.onDifficultyChanged,
  });

  final GoalType goalType;
  final TextEditingController targetValueController;
  final String targetUnit;
  final PriorityLevel priority;
  final DifficultyLevel difficulty;
  final ValueChanged<GoalType> onGoalTypeChanged;
  final ValueChanged<String> onTargetUnitChanged;
  final ValueChanged<PriorityLevel> onPriorityChanged;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;

  bool get _requiresTarget => goalType != GoalType.simpleCheck;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Goal',
      children: [
        _EnumDropdown<GoalType>(
          label: 'Goal type',
          value: goalType,
          values: GoalType.values,
          labelFor: (type) => type.label,
          onChanged: onGoalTypeChanged,
        ),
        if (_requiresTarget) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: targetValueController,
                  decoration: const InputDecoration(labelText: 'Target value'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (value) => _validateTargetValue(goalType, value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _stableTargetUnit(targetUnit),
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: _targetUnits
                      .map(
                        (unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onTargetUnitChanged(value);
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 12),
          const _InfoPanel(
            icon: Icons.check_circle_outline,
            message:
                'Simple check routines only need a completed/not completed mark.',
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EnumDropdown<PriorityLevel>(
                label: 'Priority',
                value: priority,
                values: PriorityLevel.values,
                labelFor: (value) => value.label,
                onChanged: onPriorityChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EnumDropdown<DifficultyLevel>(
                label: 'Difficulty',
                value: difficulty,
                values: DifficultyLevel.values,
                labelFor: (value) => value.label,
                onChanged: onDifficultyChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecoveryVersionsSection extends StatelessWidget {
  const _RecoveryVersionsSection({
    required this.fullDurationController,
    required this.mediumDurationController,
    required this.miniDurationController,
  });

  final TextEditingController fullDurationController;
  final TextEditingController mediumDurationController;
  final TextEditingController miniDurationController;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Recovery versions',
      children: [
        const _InfoPanel(
          icon: Icons.layers_outlined,
          message:
              'Full is the ideal session, medium is a shorter fallback, and mini is the smallest recovery version.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DurationField(
                label: 'Full min',
                controller: fullDurationController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DurationField(
                label: 'Medium min',
                controller: mediumDurationController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DurationField(
                label: 'Mini min',
                controller: miniDurationController,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.routineType,
    required this.reminderEnabled,
    required this.onChanged,
  });

  final RoutineType routineType;
  final bool reminderEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Reminders',
      children: [
        SwitchListTile(
          value: reminderEnabled,
          onChanged: onChanged,
          title: const Text('Enable reminders'),
          subtitle: Text(
            routineType == RoutineType.fixedTime
                ? 'Local reminders will be scheduled for fixed-time routines.'
                : 'Saved, but scheduler will skip this routine type in the MVP.',
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 2),
          Text(
            time.format(context),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map(
            (item) =>
                DropdownMenuItem(value: item, child: Text(labelFor(item))),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final parsed = int.tryParse(value ?? '');
        if (parsed == null || parsed <= 0) return 'Required';
        return null;
      },
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _MessagePanel(
      icon: icon,
      message: message,
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
      foregroundColor: colorScheme.onPrimaryContainer,
    );
  }
}

class _WarningPanel extends StatelessWidget {
  const _WarningPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _MessagePanel(
      icon: icon,
      message: message,
      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
      foregroundColor: colorScheme.onSecondaryContainer,
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: foregroundColor)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}

class _MissingRoutine extends StatelessWidget {
  const _MissingRoutine();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Routine not found.'));
  }
}

const _targetUnits = ['minutes', 'pages', 'glasses', 'reps', 'hours', 'tasks'];

enum _RepeatOption {
  todayOnly('Today only', {}),
  everyDay('Every day', {1, 2, 3, 4, 5, 6, 7}),
  weekdays('Weekdays', {1, 2, 3, 4, 5}),
  weekends('Weekends', {6, 7}),
  customDays('Custom days', {});

  const _RepeatOption(this.label, this.repeatDays);

  final String label;
  final Set<int> repeatDays;
}
