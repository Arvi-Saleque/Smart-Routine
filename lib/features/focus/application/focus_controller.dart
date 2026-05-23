import '../data/focus_repository.dart';

class FocusController {
  const FocusController(this._repository);

  final FocusRepository _repository;

  Future<FocusSaveResult> finishSession(FocusSessionDraft draft) {
    return _repository.finishSession(draft);
  }
}
