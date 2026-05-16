import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

enum GameCategory {
  calculation, // 계산 (누가 큰가요, 구구단)
  logic,       // 논리 (규칙 찾아보기)
  memory,      // 기억 (그림 스도쿠)
  perception   // 지각 (같은 모양 찾기)
}

class DifficultyProvider extends ChangeNotifier {
  final String username;
  late final SupabaseClient _supabase;
  
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

  DifficultyProvider({required this.username, SupabaseClient? supabase}) {
    _supabase = supabase ?? SupabaseManager.client;
  }

  int getLevel(GameCategory category) => _levels[category] ?? 1;

  /// 권장 반응 시간 (초) - 레벨이 높을수록 짧아짐
  double getTargetTime(GameCategory category) {
    int level = getLevel(category);
    // 베이스 5초에서 레벨당 0.3초씩 단축 (최소 2초)
    return max(2.0, 5.0 - (level * 0.3));
  }

  /// Supabase에서 초기 난이도 데이터를 불러옵니다.
  Future<void> loadLevels() async {
    try {
      final response = await _supabase
          .from('training_difficulty')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (response != null) {
        _levels[GameCategory.calculation] = response['calculation_level'] ?? 1;
        _levels[GameCategory.logic] = response['logic_level'] ?? 1;
        _levels[GameCategory.memory] = response['memory_level'] ?? 1;
        _levels[GameCategory.perception] = response['perception_level'] ?? 1;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading levels from Supabase: $e');
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
    
    // 난이도 상승 로직: 
    // 1. 최근 3회 연속 정답 AND 
    // 2. 평균 반응 시간이 권장 시간 이내일 때
    bool isConsecutiveCorrect = results.length >= 3 && results.sublist(results.length - 3).every((res) => res);
    double avgTime = times.isEmpty ? 0 : times.reduce((a, b) => a + b) / times.length;
    double targetTime = getTargetTime(category);

    if (isConsecutiveCorrect && (responseTime == null || avgTime <= targetTime)) {
      if (currentLevel < 10) {
        _levels[category] = currentLevel + 1;
        results.clear();
        times.clear();
        await _syncToSupabase();
      }
    } 
    // 난이도 하락 로직: 최근 2회 연속 오답 시 레벨 다운
    else if (results.length >= 2 && results.sublist(results.length - 2).every((res) => !res)) {
      if (currentLevel > 1) {
        _levels[category] = currentLevel - 1;
        results.clear();
        times.clear();
        await _syncToSupabase();
      }
    }

    notifyListeners();
  }

  /// Supabase에 현재 난이도 상태를 upsert 합니다.
  Future<void> _syncToSupabase() async {
    try {
      await _supabase.from('training_difficulty').upsert({
        'username': username,
        'calculation_level': _levels[GameCategory.calculation],
        'logic_level': _levels[GameCategory.logic],
        'memory_level': _levels[GameCategory.memory],
        'perception_level': _levels[GameCategory.perception],
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error syncing levels to Supabase: $e');
    }
  }
}
