class RecurrenceUtils {
  const RecurrenceUtils._();

  static bool repeatsOnWeekday(String repeatDays, int weekday) {
    return repeatDays
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .contains(weekday);
  }
}
