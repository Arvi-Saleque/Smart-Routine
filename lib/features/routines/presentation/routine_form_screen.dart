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
  final _targetUnitController = TextEditingController(text: 'minutes');
  final _fullDurationController = TextEditingController(text: '60');
  final _mediumDurationController = TextEditingController(text: '30');
  final _miniDurationController = TextEditingController(text: '10');

  String? _categoryId;
  RoutineType _routineType = RoutineType.fixedTime;
  GoalType _goalType = GoalType.duration;
  PriorityLevel _priority = PriorityLevel.medium;
  DifficultyLevel _difficulty = DifficultyLevel.normal;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  Set<int> _repeatDays = {1, 2, 3, 4, 5, 6, 7};
  bool _reminderEnabled = true;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    _targetUnitController.dispose();
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
          _FormCard(
            title: 'Basic info',
            children: [
              TextFormField(
                controller: _titleController,
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
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
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
                onChanged: (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? 'Category is required' : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormCard(
            title: 'Schedule',
            children: [
              DropdownButtonFormField<RoutineType>(
                initialValue: _routineType,
                decoration: const InputDecoration(labelText: 'Routine type'),
                items: RoutineType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _routineType = value!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Start',
                      time: _startTime,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: 'End',
                      time: _endTime,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in DateTimeUtils.weekdayShortLabels.entries)
                    FilterChip(
                      selected: _repeatDays.contains(day.key),
                      label: Text(day.value),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _repeatDays.add(day.key);
                          } else {
                            _repeatDays.remove(day.key);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormCard(
            title: 'Goal',
            children: [
              DropdownButtonFormField<GoalType>(
                initialValue: _goalType,
                decoration: const InputDecoration(labelText: 'Goal type'),
                items: GoalType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _goalType = value!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetValueController,
                      decoration: const InputDecoration(
                        labelText: 'Target value',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: _validateOptionalPositiveNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _targetUnitController.text,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: _targetUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) _targetUnitController.text = value;
                      },
                    ),
                  ),
                ],
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
                      label: 'Difficulty',
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
          const SizedBox(height: 12),
          _FormCard(
            title: 'Recovery versions',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DurationField(
                      label: 'Full min',
                      controller: _fullDurationController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DurationField(
                      label: 'Medium min',
                      controller: _mediumDurationController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DurationField(
                      label: 'Mini min',
                      controller: _miniDurationController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
                title: const Text('Enable reminders'),
                contentPadding: EdgeInsets.zero,
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
    _targetUnitController.text = data.targetUnit ?? 'minutes';
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
    _reminderEnabled = data.reminderEnabled;
    _initialized = true;
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
    if (endMinutes <= startMinutes) {
      messenger.showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    if (_repeatDays.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select at least one repeat day.')),
      );
      return;
    }

    final full = int.parse(_fullDurationController.text);
    final medium = int.parse(_mediumDurationController.text);
    final mini = int.parse(_miniDurationController.text);
    if (mini > medium || medium > full) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Mini must be <= medium, and medium must be <= full.'),
        ),
      );
      return;
    }

    final repository = ref.read(routineRepositoryProvider);
    final data = RoutineFormData(
      title: _titleController.text,
      description: _descriptionController.text,
      categoryId: _categoryId!,
      routineType: _routineType,
      goalType: _goalType,
      targetValue: _targetValueController.text.trim().isEmpty
          ? null
          : double.parse(_targetValueController.text),
      targetUnit: _targetUnitController.text,
      priority: _priority,
      difficulty: _difficulty,
      startTimeMinutes: startMinutes,
      endTimeMinutes: endMinutes,
      repeatDays: _repeatDays,
      fullDurationMinutes: full,
      mediumDurationMinutes: medium,
      miniDurationMinutes: mini,
      reminderEnabled: _reminderEnabled,
      timezone: DateTime.now().timeZoneName,
    );

    setState(() => _saving = true);
    try {
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

  String? _validateOptionalPositiveNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) return 'Use a positive number';
    return null;
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
