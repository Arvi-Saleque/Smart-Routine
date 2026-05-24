import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/enums/routine_status.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/routine_card.dart';
import '../../../shared/widgets/score_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/data/settings_repository.dart';
import '../../today/application/today_providers.dart';
import '../../today/data/today_repository.dart';
import '../application/calendar_providers.dart';
import '../data/calendar_repository.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(title: 'Calendar', body: _CalendarBody());
  }
}

class _CalendarBody extends ConsumerStatefulWidget {
  const _CalendarBody();

  @override
  ConsumerState<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends ConsumerState<_CalendarBody> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Future<CalendarMonthSummary> _monthSummary;
  late Future<TodayTimeline> _selectedTimeline;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _monthSummary = _loadMonthSummary();
    _selectedTimeline = _loadSelectedTimeline();
  }

  @override
  Widget build(BuildContext context) {
    final focusedDay = _focusedDay;
    final selectedDay = _selectedDay;
    final startOfWeek = ref
        .watch(startOfWeekProvider)
        .maybeWhen(data: (value) => value, orElse: () => StartOfWeek.saturday);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Monthly view',
          subtitle: 'Activity history, missed blocks, and saved scores.',
        ),
        const SizedBox(height: 16),
        FutureBuilder<CalendarMonthSummary>(
          future: _monthSummary,
          builder: (context, snapshot) {
            return _CalendarPanel(
              focusedDay: focusedDay,
              selectedDay: selectedDay,
              startOfWeek: startOfWeek,
              summary: snapshot.data,
              loading: snapshot.connectionState == ConnectionState.waiting,
              onDaySelected: _selectDay,
              onPageChanged: _changeFocusedMonth,
            );
          },
        ),
        const SizedBox(height: 24),
        FutureBuilder<TodayTimeline>(
          future: _selectedTimeline,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load selected day',
                message: '${snapshot.error}',
              );
            }
            final timeline = snapshot.data;
            if (timeline == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _SelectedDaySummary(
              selectedDay: selectedDay,
              timeline: timeline,
            );
          },
        ),
      ],
    );
  }

  Future<CalendarMonthSummary> _loadMonthSummary() {
    return ref.read(calendarRepositoryProvider).getMonthSummary(_focusedDay);
  }

  Future<TodayTimeline> _loadSelectedTimeline() {
    return ref
        .read(todayRepositoryProvider)
        .getTimelineForDate(_selectedDay, saveScore: false);
  }

  void _selectDay(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = DateTime(selected.year, selected.month, selected.day);
      _focusedDay = DateTime(focused.year, focused.month);
      _monthSummary = _loadMonthSummary();
      _selectedTimeline = _loadSelectedTimeline();
    });
  }

  void _changeFocusedMonth(DateTime focused) {
    setState(() {
      _focusedDay = DateTime(focused.year, focused.month);
      _monthSummary = _loadMonthSummary();
    });
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.focusedDay,
    required this.selectedDay,
    required this.startOfWeek,
    required this.summary,
    required this.loading,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final StartOfWeek startOfWeek;
  final CalendarMonthSummary? summary;
  final bool loading;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TableCalendar<CalendarDayMarker>(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: focusedDay,
              startingDayOfWeek: startOfWeek == StartOfWeek.sunday
                  ? StartingDayOfWeek.sunday
                  : StartingDayOfWeek.saturday,
              selectedDayPredicate: (day) => isSameDay(day, selectedDay),
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              calendarFormat: CalendarFormat.month,
              eventLoader: (day) {
                final marker = summary?.markerFor(day);
                if (marker == null || !marker.hasActivity) return const [];
                return [marker];
              },
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              calendarBuilders: CalendarBuilders<CalendarDayMarker>(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return _CalendarMarker(marker: events.first);
                },
              ),
            ),
            if (loading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarMarker extends StatelessWidget {
  const _CalendarMarker({required this.marker});

  final CalendarDayMarker marker;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = marker.missedCount > 0
        ? const Color(0xFFDC2626)
        : marker.skippedCount > 0
        ? colorScheme.outline
        : marker.completedCount > 0
        ? const Color(0xFF16A34A)
        : colorScheme.secondary;

    return Positioned(
      bottom: 4,
      child: Container(
        width: 20,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SelectedDaySummary extends StatelessWidget {
  const _SelectedDaySummary({
    required this.selectedDay,
    required this.timeline,
  });

  final DateTime selectedDay;
  final TodayTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMMEEEEd().format(selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: dateLabel, subtitle: timeline.progressMessage),
        const SizedBox(height: 12),
        ScoreCard(
          title: 'Selected day score',
          score: timeline.dailyScore?.score,
          message: timeline.scoreMessage,
        ),
        const SizedBox(height: 12),
        _StatusSummary(timeline: timeline),
        const SizedBox(height: 16),
        if (timeline.entries.isEmpty)
          const EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No activities planned',
            message: 'This day has no scheduled activity blocks.',
          )
        else
          for (final entry in timeline.entries) ...[
            RoutineCard(
              title: entry.detail.routine.title,
              timeRange: entry.timeRangeLabel,
              status: entry.status,
              category: CategoryChip(
                label: entry.detail.category.name,
                icon: categoryIconFromName(entry.detail.category.iconName),
                color: Color(entry.detail.category.colorValue),
              ),
              goal: entry.detail.goalLabel,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.timeline});

  final TodayTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final statuses = {
      'Planned': timeline.entries.length,
      'Done': timeline.completedCount,
      'Skipped': timeline.skippedCount,
      'Missed': timeline.missedCount,
      'Recovery': timeline.entries
          .where((entry) => entry.status == RoutineStatus.recovered)
          .length,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in statuses.entries)
          Chip(
            avatar: CircleAvatar(child: Text('${entry.value}')),
            label: Text(entry.key),
          ),
      ],
    );
  }
}
