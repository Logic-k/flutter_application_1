import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

const _adminCode = 'memorylink2024';
const _prefKey = 'is_admin_logged_in';

class AdminProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;

  int totalUsers = 0;
  int dauCount = 0;
  int newUsersThisWeek = 0;
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> atRiskUsers = [];
  Map<String, double> avgScores = {};

  bool get isAdminLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  final _db = DatabaseHelper();

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<bool> login(String code) async {
    if (code.trim() != _adminCode) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    _isLoggedIn = true;
    notifyListeners();
    return true;
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
      newUsersThisWeek = await _db.getNewUsersThisWeek();
      allUsers = await _db.getAllUsers();
      atRiskUsers = await _db.getAtRiskUsers();
      avgScores = await _db.getAvgScoresByCategory();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
