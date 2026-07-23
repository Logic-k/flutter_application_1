import 'package:flutter/foundation.dart';

import 'application/training_attempt_input.dart';
import 'application/training_completion_result.dart';
import 'application/training_completion_service.dart';
import 'data/training_progress_repository.dart';
import 'domain/training_catalog.dart';
import 'domain/training_progress_rules.dart';

class TrainingProgressProvider extends ChangeNotifier {
  TrainingProgressProvider({
    required TrainingProgressRepository repository,
    required TrainingCompletionService completionService,
    required TrainingClock clock,
  }) : _repository = repository,
       _completionService = completionService,
       _clock = clock;

  final TrainingProgressRepository _repository;
  final TrainingCompletionService _completionService;
  final TrainingClock _clock;

  int _generation = 0;
  int? _userId;
  bool _isLoading = false;
  bool _isSaving = false;
  Object? _error;
  int _totalXp = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _todayDistinctActivityCount = 0;
  Set<String> _unlockedActivityIds = const {};
  Map<String, TrainingActivityProgressRecord> _activityProgressById = const {};

  int? get userId => _userId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  Object? get error => _error;
  int get totalXp => _totalXp;
  int get level => levelForTotalXp(_totalXp);
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get todayDistinctActivityCount => _todayDistinctActivityCount;
  Set<String> get unlockedActivityIds => _unlockedActivityIds;
  Set<String> get unlocks => _unlockedActivityIds;
  Map<String, TrainingActivityProgressRecord> get activityProgressById =>
      _activityProgressById;
  Map<String, TrainingActivityProgressRecord> get activityProgress =>
      _activityProgressById;

  bool isUnlocked(String activityId) {
    final activity = trainingActivityById(activityId);
    return activity.isAlwaysUnlocked ||
        _unlockedActivityIds.contains(activityId);
  }

  Future<void> updateUser(int? userId) async {
    final generation = ++_generation;
    _userId = userId;
    _clearProgress();
    _error = null;
    _isSaving = false;
    _isLoading = userId != null;
    notifyListeners();

    if (userId != null) {
      await _load(userId, generation, manageLoading: true);
    }
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await _load(userId, _generation, manageLoading: true);
  }

  Future<TrainingCompletionResult> complete(TrainingAttemptInput input) async {
    final userId = _userId;
    if (userId == null || input.userId != userId) {
      throw StateError('Training completion requires the active user');
    }

    final generation = _generation;
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _completionService.complete(input);
      if (_isCurrent(userId, generation)) {
        await _load(userId, generation, manageLoading: false);
      }
      return result;
    } catch (error) {
      if (_isCurrent(userId, generation)) {
        _error = error;
      }
      rethrow;
    } finally {
      if (_isCurrent(userId, generation)) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<void> _load(
    int userId,
    int generation, {
    required bool manageLoading,
  }) async {
    if (manageLoading && _isCurrent(userId, generation)) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final values = await Future.wait<Object?>([
        _repository.getUserProgress(userId),
        _repository.getActivityProgress(userId),
        _repository.getUnlocks(userId),
        _repository.getDistinctCompletedActivityCount(
          userId,
          seoulDateString(_clock()),
        ),
      ]);
      if (!_isCurrent(userId, generation)) {
        return;
      }

      final progress = values[0] as TrainingUserProgressRecord?;
      final activityProgress =
          values[1] as List<TrainingActivityProgressRecord>;
      final unlocks = values[2] as List<TrainingUnlockRecord>;
      _totalXp = progress?.totalXp ?? 0;
      _currentStreak = progress?.currentStreak ?? 0;
      _longestStreak = progress?.longestStreak ?? 0;
      _todayDistinctActivityCount = values[3] as int;
      _unlockedActivityIds = Set.unmodifiable(
        unlocks.map((unlock) => unlock.activityId),
      );
      _activityProgressById = Map.unmodifiable({
        for (final item in activityProgress) item.activityId: item,
      });
      _error = null;
    } catch (error) {
      if (_isCurrent(userId, generation)) {
        _clearProgress();
        _error = error;
      }
    } finally {
      if (manageLoading && _isCurrent(userId, generation)) {
        _isLoading = false;
      }
      if (_isCurrent(userId, generation)) {
        notifyListeners();
      }
    }
  }

  bool _isCurrent(int userId, int generation) =>
      _userId == userId && _generation == generation;

  void _clearProgress() {
    _totalXp = 0;
    _currentStreak = 0;
    _longestStreak = 0;
    _todayDistinctActivityCount = 0;
    _unlockedActivityIds = const {};
    _activityProgressById = const {};
  }
}
