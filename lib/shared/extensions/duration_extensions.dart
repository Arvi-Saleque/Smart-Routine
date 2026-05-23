extension DurationExtensions on Duration {
  String get compactLabel {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
}
