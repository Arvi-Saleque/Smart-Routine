import '../../routines/data/routine_repository.dart';
import '../data/focus_repository.dart';

class FocusController {
  const FocusController(this._repository);

  final FocusRepository _repository;

  Future<void> startSession(RoutineDetail detail, {DateTime? startedAt}) {
    return _repository.startSession(detail, startedAt: startedAt);
  }

  Future<FocusSaveResult> finishSession(FocusSessionDraft draft) {
    return _repository.finishSession(draft);
  }
}
