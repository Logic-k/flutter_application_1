import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth_service.dart';
import '../../core/firebase_service.dart';

enum GameCategory {
  calculation, // 계산 (누가 큰가요, 구구단)
  logic,       // 논리 (규칙 찾아보기)
  memory,      // 기억 (그림 스도쿠)
  perception   // 지각 (같은 모양 찾기)
}

class DifficultyProvider extends ChangeNotifier {
  String _username;
  String get username => _username;

  // 게임 카테고리별 현재 난이도 (1 ~ 10)
  final Map<GameCategory, int> _levels = {
    GameCategory.calculation: 1,
    GameCategory.logic: 1,
    GameCategory.memory: 1,
    GameCategory.perception: 1,
  };

  // 최근 수행 데이터 (난이도 조절용)
  final Map<GameCategory, List<bool>> _recentResults = {
    GameCategory.calculation: [],
    GameCategory.logic: [],
    GameCategory.memory: [],
    GameCategory.perception: [],
  };

  // 최근 반응 시간 데이터 (초 단위)
  final Map<GameCategory, List<double>> _recentResponseTimes = {
    GameCategory.calculation: [],
    GameCategory.logic: [],
    GameCategory.memory: [],
    GameCategory.perception: [],
  };

  DifficultyProvider({required String username}) : _username = username;

  /// 로그인/로그아웃 시 사용자 전환. 사용자가 바뀌면 레벨을 초기화하고
  /// 새 사용자의 난이도를 기기에서 다시 불러온다.
  Future<void> setUsername(String username) async {
    if (username == _username) return;
    _username = username;
    _changedSinceLoad = false;
    for (final category in GameCategory.values) {
      _levels[category] = 1;
      _recentResults[category]!.clear();
      _recentResponseTimes[category]!.clear();
    }
    notifyListeners();
    if (_username.isNotEmpty) await loadLevels();
  }

  int getLevel(GameCategory category) => _levels[category] ?? 1;

  /// 권장 반응 시간 (초) - 레벨이 높을수록 짧아짐
  double getTargetTime(GameCategory category) {
    int level = getLevel(category);
    return max(2.0, 5.0 - (level * 0.3));
  }

  // 난이도는 기기에만 저장한다(SharedPreferences, 아이디별).
  // 예전에는 Firestore에 '익명 uid_아이디' 문서로 올렸지만, uid가 설치 단위라
  // 기기 간 동기화가 일어나지 않았고 재설치·오프라인에서는 레벨이 1로 돌아갔다.
  static const _prefPrefix = 'difficulty_levels_';

  /// 이 기기 계정의 난이도 저장 키. 계정 삭제 때 함께 지운다.
  static String prefKeyFor(String username) => '$_prefPrefix$username';
  static const _fieldNames = {
    GameCategory.calculation: 'calculation_level',
    GameCategory.logic: 'logic_level',
    GameCategory.memory: 'memory_level',
    GameCategory.perception: 'perception_level',
  };

  /// 사용자가 이번 로그인 뒤에 레벨을 바꿨는가. 늦게 도착한 예전 클라우드 값이
  /// 새 진행을 덮지 않게 한다.
  bool _changedSinceLoad = false;
  bool _waitingForFirebase = false;

  /// 기기에 저장된 난이도를 불러온다. 없으면 예전 클라우드 문서를 한 번 옮겨 온다.
  Future<void> loadLevels() async {
    final requested = _username;
    if (requested.isEmpty) return;
    final stored = await _readLocal(requested);
    if (requested != _username) return;
    if (stored != null) {
      _apply(stored);
      return;
    }
    // 자동 로그인은 Firebase 초기화보다 먼저 끝난다. 준비되면 그때 한 번 옮긴다.
    if (FirebaseService.isAvailable) {
      await _migrateAndApply(requested);
    } else if (!_waitingForFirebase) {
      _waitingForFirebase = true;
      FirebaseService.availability.addListener(_onFirebaseReady);
    }
  }

  void _onFirebaseReady() {
    if (!FirebaseService.isAvailable) return;
    FirebaseService.availability.removeListener(_onFirebaseReady);
    _waitingForFirebase = false;
    final name = _username;
    if (name.isNotEmpty) _migrateAndApply(name);
  }

  Future<void> _migrateAndApply(String name) async {
    final migrated = await _migrateFromCloud(name);
    if (migrated == null || name != _username || _changedSinceLoad) return;
    _apply(migrated);
  }

  void _apply(Map<String, dynamic> stored) {
    for (final entry in _fieldNames.entries) {
      final value = stored[entry.value];
      if (value is int) _levels[entry.key] = value.clamp(1, 10);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_waitingForFirebase) FirebaseService.availability.removeListener(_onFirebaseReady);
    super.dispose();
  }

  Future<Map<String, dynamic>?> _readLocal(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefPrefix$name');
      return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Difficulty] 기기 난이도 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _saveLocal() async {
    final name = _username;
    if (name.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$name', jsonEncode({
        for (final entry in _fieldNames.entries) entry.value: _levels[entry.key],
      }));
    } catch (e) {
      debugPrint('[Difficulty] 기기 난이도 저장 실패: $e');
    }
  }

  /// 예전 Firestore 문서가 있으면 기기로 옮기고 서버 문서를 지운다(한 번).
  Future<Map<String, dynamic>?> _migrateFromCloud(String name) async {
    if (!FirebaseService.isAvailable) return null;
    final uid = AuthService.uid;
    if (uid == null) return null;
    try {
      final ref = FirebaseService.db.collection('training_difficulty').doc('${uid}_$name');
      final doc = await ref.get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      final levels = {
        for (final field in _fieldNames.values)
          if (data[field] is int) field: data[field],
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$name', jsonEncode(levels));
      await ref.delete();
      return levels;
    } catch (e) {
      debugPrint('[Difficulty] 예전 난이도 옮기기 실패(다음 실행 때 다시 시도): $e');
      return null;
    }
  }

  /// 게임 결과 및 반응 시간을 반영하여 난이도를 실시간으로 조절합니다.
  Future<void> updatePerformance(GameCategory category, bool isCorrect, {double? responseTime}) async {
    final results = _recentResults[category]!;
    final times = _recentResponseTimes[category]!;

    results.add(isCorrect);
    if (responseTime != null) times.add(responseTime);

    if (results.length > 5) results.removeAt(0);
    if (times.length > 5) times.removeAt(0);

    int currentLevel = _levels[category]!;

    bool isConsecutiveCorrect = results.length >= 3 && results.sublist(results.length - 3).every((res) => res);
    double avgTime = times.isEmpty ? 0 : times.reduce((a, b) => a + b) / times.length;
    double targetTime = getTargetTime(category);

    if (isConsecutiveCorrect && (responseTime == null || avgTime <= targetTime)) {
      if (currentLevel < 10) {
        _levels[category] = currentLevel + 1;
        results.clear();
        times.clear();
        _changedSinceLoad = true;
        await _saveLocal();
      }
    } else if (results.length >= 2 && results.sublist(results.length - 2).every((res) => !res)) {
      if (currentLevel > 1) {
        _levels[category] = currentLevel - 1;
        results.clear();
        times.clear();
        _changedSinceLoad = true;
        await _saveLocal();
      }
    }

    notifyListeners();
  }

}
