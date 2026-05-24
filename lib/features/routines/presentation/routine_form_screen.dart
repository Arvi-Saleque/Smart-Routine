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
  final _miniDurationController = TextEditingController(text: '10');

  String? _categoryId;
  RoutineType _routineType = RoutineType.fixedTime;
  GoalType _goalType = GoalType.simpleCheck;
  PriorityLevel _priority = PriorityLevel.medium;
  DifficultyLevel _difficulty = DifficultyLevel.normal;
  String _targetUnit = 'minutes';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  Set<int> _repeatDays = {1, 2, 3, 4, 5, 6, 7};
  _RepeatOption _repeatOption = _RepeatOption.everyDay;
  String? _specificDate;
  bool _reminderEnabled = true;
  bool _recoveryEnabled = true;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    _miniDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Activity' : 'Add Activity';
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
            title: widget.isEditing ? 'Tune this activity' : 'Add an activity',
            subtitle: 'Save one scheduled activity or time block.',
          ),
          const SizedBox(height: 16),
          _BasicInfoSection(
            titleController: _titleController,
            categories: categories,
            categoryId: _categoryId,
            startTime: _startTime,
            endTime: _endTime,
            repeatOption: _repeatOption,
            repeatDays: _repeatDays,
            reminderEnabled: _reminderEnabled,
            onCategoryChanged: (value) => setState(() => _categoryId = value),
            onPickStart: () => _pickTime(isStart: true),
            onPickEnd: () => _pickTime(isStart: false),
            onRepeatOptionChanged: _setRepeatOption,
            onRepeatDayChanged: _setRepeatDay,
            onReminderChanged: (value) =>
                setState(() => _reminderEnabled = value),
          ),
          const SizedBox(height: 12),
          _ExpandableFormSection(
            title: 'Tracking',
            children: [
              _TrackingSection(
                goalType: _goalType,
                targetValueController: _targetValueController,
                targetUnit: _targetUnit,
                onGoalTypeChanged: (value) => setState(() {
                  _goalType = value;
                  if (value == GoalType.simpleCheck) {
                    _targetValueController.clear();
                  }
                }),
                onTargetUnitChanged: (value) =>
                    setState(() => _targetUnit = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ExpandableFormSection(
            title: 'Recovery',
            children: [
              _RecoverySection(
                recoveryEnabled: _recoveryEnabled,
                miniDurationController: _miniDurationController,
                onRecoveryChanged: (value) =>
                    setState(() => _recoveryEnabled = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ExpandableFormSection(
            title: 'Advanced',
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _EnumDropdown<PriorityLevel>(
                      label: 'Priority',
                      value: _priority,
                      values: PriorityLevel.values,
                      labelFor: (value) => value.label,
                      onChanged: (value) => setState(() => _priority = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EnumDropdown<DifficultyLevel>(
                      label: 'Effort Level',
                      value: _difficulty,
                      values: DifficultyLevel.values,
                      labelFor: (value) => value.label,
                      onChanged: (value) => setState(() => _difficulty = value),
                    ),
                  ),
                ],
              ),
            ],
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
            label: Text(widget.isEditing ? 'Save changes' : 'Add activity'),
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
    _recoveryEnabled = data.miniDurationMinutes < data.fullDurationMinutes;
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
    if (_repeatOption == _RepeatOption.customDays && _repeatDays.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select at least one custom day.')),
      );
      return;
    }
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
    final plannedDuration = endMinutes - startMinutes;
    final fullDuration = plannedDuration <= 0 ? 0 : plannedDuration;
    final selectedMiniDuration =
        int.tryParse(_miniDurationController.text) ?? 10;
    final miniDuration = fullDuration <= 0
        ? 0
        : _recoveryEnabled
        ? selectedMiniDuration.clamp(1, fullDuration).toInt()
        : fullDuration;
    // TODO: Add a recoveryEnabled column later. For now, disabled recovery is
    // represented by making mini equal to full so recovery suggestions can be
    // hidden without changing the schema.
    final mediumDuration = fullDuration <= 0
        ? 0
        : _recoveryEnabled
        ? ((fullDuration / 2).round()).clamp(miniDuration, fullDuration).toInt()
        : fullDuration;
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
      fullDurationMinutes: fullDuration,
      mediumDurationMinutes: mediumDuration,
      miniDurationMinutes: miniDuration,
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
    required this.categories,
    required this.categoryId,
    required this.startTime,
    required this.endTime,
    required this.repeatOption,
    required this.repeatDays,
    required this.reminderEnabled,
    required this.onCategoryChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onRepeatOptionChanged,
    required this.onRepeatDayChanged,
    required this.onReminderChanged,
  });

  final TextEditingController titleController;
  final List<Category> categories;
  final String? categoryId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final _RepeatOption repeatOption;
  final Set<int> repeatDays;
  final bool reminderEnabled;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<_RepeatOption> onRepeatOptionChanged;
  final void Function(int weekday, bool selected) onRepeatDayChanged;
  final ValueChanged<bool> onReminderChanged;

  @override
  Widget build(BuildContext context) {
    final stableCategoryId =
        categories.any((category) => category.id == categoryId)
        ? categoryId
        : null;

    return _FormCard(
      title: 'Basic',
      children: [
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Activity name'),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Activity name is required';
            }
            return null;
          },
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
        const SizedBox(height: 12),
        const _InfoPanel(
          icon: Icons.repeat,
          message:
              'Repeating activities automatically appear on future selected days. Today-only activities appear once.',
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
        SwitchListTile(
          value: reminderEnabled,
          onChanged: onReminderChanged,
          title: const Text('Reminder'),
          subtitle: const Text('Schedule local reminders for this activity.'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _TrackingSection extends StatelessWidget {
  const _TrackingSection({
    required this.goalType,
    required this.targetValueController,
    required this.targetUnit,
    required this.onGoalTypeChanged,
    required this.onTargetUnitChanged,
  });

  final GoalType goalType;
  final TextEditingController targetValueController;
  final String targetUnit;
  final ValueChanged<GoalType> onGoalTypeChanged;
  final ValueChanged<String> onTargetUnitChanged;

  bool get _requiresTarget => goalType != GoalType.simpleCheck;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<GoalType>(
          initialValue: goalType,
          decoration: const InputDecoration(labelText: 'Tracking Method'),
          items: const [
            DropdownMenuItem(
              value: GoalType.simpleCheck,
              child: Text('Just mark as done'),
            ),
            DropdownMenuItem(
              value: GoalType.duration,
              child: Text('Track time'),
            ),
            DropdownMenuItem(
              value: GoalType.quantity,
              child: Text('Track quantity'),
            ),
            DropdownMenuItem(value: GoalType.count, child: Text('Track count')),
          ],
          onChanged: (value) {
            if (value != null) onGoalTypeChanged(value);
          },
        ),
        if (_requiresTarget) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: targetValueController,
                  decoration: const InputDecoration(labelText: 'Target'),
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
            message: 'This activity only needs a completed/not completed mark.',
          ),
        ],
      ],
    );
  }
}

class _RecoverySection extends StatelessWidget {
  const _RecoverySection({
    required this.recoveryEnabled,
    required this.miniDurationController,
    required this.onRecoveryChanged,
  });

  final bool recoveryEnabled;
  final TextEditingController miniDurationController;
  final ValueChanged<bool> onRecoveryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<bool>(
          initialValue: recoveryEnabled,
          decoration: const InputDecoration(
            labelText: 'If I miss this activity',
          ),
          items: const [
            DropdownMenuItem(
              value: true,
              child: Text('Suggest a mini version'),
            ),
            DropdownMenuItem(
              value: false,
              child: Text('No recovery suggestion'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onRecoveryChanged(value);
          },
        ),
        if (recoveryEnabled) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: miniDurationController,
            decoration: const InputDecoration(
              labelText: 'Mini version duration',
              suffixText: 'min',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              final parsed = int.tryParse(value ?? '');
              if (parsed == null || parsed <= 0) return 'Required';
              return null;
            },
          ),
        ],
      ],
    );
  }
}

class _ExpandableFormSection extends StatelessWidget {
  const _ExpandableFormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
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
    return const Center(child: Text('Activity not found.'));
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
