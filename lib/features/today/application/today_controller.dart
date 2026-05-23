import '../../../core/enums/skip_reason.dart';
import '../data/today_repository.dart';

class TodayController {
  const TodayController(this._repository);

  final TodayRepository _repository;

  Future<void> markCompleted(TodayTimelineEntry entry) {
    return _repository.markCompleted(entry);
  }

  Future<void> markSkipped(TodayTimelineEntry entry, SkipReason reason) {
    return _repository.markSkipped(entry, reason.name);
  }
}
