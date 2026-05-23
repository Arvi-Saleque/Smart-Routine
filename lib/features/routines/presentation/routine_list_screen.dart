import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/routine_providers.dart';
import '../data/routine_repository.dart';

class RoutineListScreen extends ConsumerStatefulWidget {
  const RoutineListScreen({super.key});

  @override
  ConsumerState<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends ConsumerState<RoutineListScreen> {
  String? _categoryId;
  bool? _activeOnly = true;

  @override
  Widget build(BuildContext context) {
    final routines = ref.watch(routineDetailsProvider);
    final categories = ref.watch(categoriesProvider);

    return AppScaffold(
      title: 'Routines',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/routine/create'),
        tooltip: 'Add routine',
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'All routines',
            subtitle: 'Create, edit, pause, or delete your time blocks.',
          ),
          const SizedBox(height: 16),
          categories.when(
            data: (items) => _RoutineFilters(
              categories: items,
              selectedCategoryId: _categoryId,
              activeOnly: _activeOnly,
              onCategoryChanged: (value) => setState(() => _categoryId = value),
              onActiveChanged: (value) => setState(() => _activeOnly = value),
            ),
            error: (error, _) => Text('Could not load categories: $error'),
            loading: () => const LinearProgressIndicator(),
          ),
          const SizedBox(height: 16),
          routines.when(
            data: _buildRoutineList,
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load routines',
              message: '$error',
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineList(List<RoutineDetail> routines) {
    final filtered = routines.where((detail) {
      final matchesCategory =
          _categoryId == null || detail.category.id == _categoryId;
      final matchesActive =
          _activeOnly == null || detail.routine.isActive == _activeOnly;
      return matchesCategory && matchesActive;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.checklist_outlined,
        title: 'Build your first routine',
        message: 'Create a routine to start planning your day by time blocks.',
        action: PrimaryButton(
          label: 'Add routine',
          icon: Icons.add,
          onPressed: () => context.go('/routine/create'),
        ),
      );
    }

    return Column(
      children: [
        for (final detail in filtered) ...[
          _RoutineListTile(detail: detail),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RoutineFilters extends StatelessWidget {
  const _RoutineFilters({
    required this.categories,
    required this.selectedCategoryId,
    required this.activeOnly,
    required this.onCategoryChanged,
    required this.onActiveChanged,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final bool? activeOnly;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool?> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                selected: selectedCategoryId == null,
                label: const Text('All'),
                onSelected: (_) => onCategoryChanged(null),
              ),
              const SizedBox(width: 8),
              for (final category in categories) ...[
                FilterChip(
                  selected: selectedCategoryId == category.id,
                  label: Text(category.name),
                  avatar: Icon(categoryIconFromName(category.iconName)),
                  onSelected: (_) => onCategoryChanged(category.id),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool?>(
          segments: const [
            ButtonSegment(value: true, label: Text('Active')),
            ButtonSegment(value: false, label: Text('Paused')),
            ButtonSegment(value: null, label: Text('All')),
          ],
          selected: {activeOnly},
          onSelectionChanged: (values) => onActiveChanged(values.first),
        ),
      ],
    );
  }
}

class _RoutineListTile extends ConsumerWidget {
  const _RoutineListTile({required this.detail});

  final RoutineDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(detail.category.colorValue);
    final repository = ref.read(routineRepositoryProvider);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/routine/${detail.routine.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.routine.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(detail.scheduleLabel),
                      ],
                    ),
                  ),
                  Switch(
                    value: detail.routine.isActive,
                    onChanged: (value) =>
                        repository.setRoutineActive(detail.routine.id, value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CategoryChip(
                    label: detail.category.name,
                    icon: categoryIconFromName(detail.category.iconName),
                    color: color,
                  ),
                  Chip(label: Text(detail.repeatLabel)),
                  Chip(label: Text(detail.goalLabel)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
