import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String get weekdayMonthDay => DateFormat('EEEE, MMMM d').format(this);
}
