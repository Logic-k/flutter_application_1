import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/firebase_service.dart';

enum GameCategory {
  calculation, // 계산 (누가 큰가요, 구구단)
  logic,       // 논리 (규칙 찾아보기)
  memory,      // 기억 (그림 스도쿠)
  perception   // 지각 (같은 모양 찾기)
}

class DifficultyProvider extends ChangeNotifier {
  final String username;

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

  DifficultyProvider({required this.username});

  int getLevel(GameCategory category) => _levels[category] ?? 1;

  /// 권장 반응 시간 (초) - 레벨이 높을수록 짧아짐
  double getTargetTime(GameCategory category) {
    int level = getLevel(category);
    return max(2.0, 5.0 - (level * 0.3));
  }

  /// Firestore에서 초기 난이도 데이터를 불러옵니다.
  Future<void> loadLevels() async {
    if (username.isEmpty) return;
    try {
      final doc = await FirebaseService.db
          .collection('training_difficulty')
          .doc(username)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _levels[GameCategory.calculation] = data['calculation_level'] as int? ?? 1;
        _levels[GameCategory.logic] = data['logic_level'] as int? ?? 1;
        _levels[GameCategory.memory] = data['memory_level'] as int? ?? 1;
        _levels[GameCategory.perception] = data['perception_level'] as int? ?? 1;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading levels from Firestore: $e');
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
        await _syncToFirestore();
      }
    } else if (results.length >= 2 && results.sublist(results.length - 2).every((res) => !res)) {
      if (currentLevel > 1) {
        _levels[category] = currentLevel - 1;
        results.clear();
        times.clear();
        await _syncToFirestore();
      }
    }

    notifyListeners();
  }

  /// Firestore에 현재 난이도 상태를 저장합니다.
  Future<void> _syncToFirestore() async {
    if (username.isEmpty) return;
    try {
      await FirebaseService.db
          .collection('training_difficulty')
          .doc(username)
          .set({
        'calculation_level': _levels[GameCategory.calculation],
        'logic_level': _levels[GameCategory.logic],
        'memory_level': _levels[GameCategory.memory],
        'perception_level': _levels[GameCategory.perception],
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing levels to Firestore: $e');
    }
  }
}
