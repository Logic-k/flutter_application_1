import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';
import 'database_helper.dart';

/// 디버그·프로파일 빌드에서만 통하는 개발용 코드('memorylink2024')의 다이제스트.
///
/// 값 자체는 비밀이 아니다 — 릴리스에서는 [AppConfig.isAdminPortalEnabled]가
/// false라 이 경로에 아예 닿지 않고, 운영 코드는 dart-define으로 따로 주입한다.
const _devAdminCodeSha256 =
    'ffe17710402e3cc72ce4d4bf800cdaf2345a39463bc7b6d00256ae4c13e328e7';

const _prefKey = 'is_admin_logged_in';

class AdminProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;

  int totalUsers = 0;
  int dauCount = 0;
  int weeklyActiveUsers = 0;
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> atRiskUsers = [];
  Map<String, double> avgScores = {};

  bool get isAdminLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  final _db = DatabaseHelper();

  Future<void> checkLoginStatus() async {
    // 포털이 꺼진 빌드에서는 예전에 남은 세션 플래그가 있어도 무시한다.
    // 켜져 있던 빌드로 로그인한 뒤 릴리스로 갈아끼우는 경로를 막는다.
    if (!AppConfig.isAdminPortalEnabled) {
      _isLoggedIn = false;
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<bool> login(String code) async {
    if (!AppConfig.isAdminPortalEnabled) return false;
    if (!_matchesAdminCode(code.trim())) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  /// 입력 코드를 해시해서 대조한다. 평문은 메모리에만 잠깐 머문다.
  bool _matchesAdminCode(String input) {
    if (input.isEmpty) return false;
    final expected = AppConfig.adminCodeSha256.isNotEmpty
        ? AppConfig.adminCodeSha256.toLowerCase()
        : _devAdminCodeSha256;
    return sha256.convert(utf8.encode(input)).toString() == expected;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> loadDashboardStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      totalUsers = await _db.getTotalUserCount();
      dauCount = await _db.getDauCount();
      weeklyActiveUsers = await _db.getWeeklyActiveUsers();
      allUsers = await _db.getAllUsers();
      atRiskUsers = await _db.getAtRiskUsers();
      avgScores = await _db.getAvgScoresByCategory();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
