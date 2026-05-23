import 'package:flutter/material.dart';

class DateTimeUtils {
  const DateTimeUtils._();

  static int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  static TimeOfDay minutesToTimeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static String formatMinutesOfDay(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  static String formatTimeRange(int startMinutes, int endMinutes) {
    return '${formatMinutesOfDay(startMinutes)} - ${formatMinutesOfDay(endMinutes)}';
  }

  static String encodeRepeatDays(Set<int> weekdays) {
    final sorted = weekdays.toList()..sort();
    return sorted.join(',');
  }

  static Set<int> decodeRepeatDays(String repeatDays) {
    if (repeatDays.trim().isEmpty) return {};
    return repeatDays
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .where((value) => value >= 1 && value <= 7)
        .toSet();
  }

  static String formatRepeatDays(String repeatDays) {
    final days = decodeRepeatDays(repeatDays);
    if (days.length == 7) return 'Every day';
    if (_setEquals(days, {1, 2, 3, 4, 5})) return 'Weekdays';
    if (_setEquals(days, {6, 7})) return 'Weekends';
    return days
        .map((day) => weekdayShortLabels[day])
        .whereType<String>()
        .join(', ');
  }

  static bool _setEquals(Set<int> left, Set<int> right) {
    return left.length == right.length && left.containsAll(right);
  }

  static const weekdayShortLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
}
