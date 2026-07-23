import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

enum OnboardingGoal { prevention, concern, family }

class UserProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  
  UserProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // Auth state
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  
  // Onboarding state
  bool _hasConsent = false;
  OnboardingGoal? _goal;
  
  // Assessment & Training state (Daily/Persistent)
  int? _age;
  double? _weight;
  String? _bloodType;
  String? _medications;
  String? _emergencyContact;
  bool _pedometerEnabled = false;
  
  final Map<int, int> _surveyAnswers = {};
  double _calculationScore = 0;
  double _logicScore = 0;
  double _memoryScore = 0;
  double _attentionScore = 0;
  double _voiceScore = 0;

  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;
  String get displayName =>
      (_currentUser?['name'] as String?)?.isNotEmpty == true
          ? _currentUser!['name'] as String
          : _currentUser?['username'] as String? ?? '';
  bool get hasConsent => _hasConsent;
  OnboardingGoal? get goal => _goal;
  bool get hasCompletedOnboarding =>
      (_currentUser?['has_completed_onboarding'] ?? 0) == 1;
  
  int? get age => _age;
  double? get weight => _weight;
  String? get bloodType => _bloodType;
  String? get medications => _medications;
  String? get emergencyContact => _emergencyContact;
  bool get pedometerEnabled => _pedometerEnabled;
  
  double get calculationScore => _calculationScore;
  double get logicScore => _logicScore;
  double get memoryScore => _memoryScore;
  double get attentionScore => _attentionScore;
  double get voiceScore => _voiceScore;

  // --- Auth Methods ---
  // 자동 로그인은 비밀번호 대신 무작위 세션 토큰을 사용한다.
  // (비밀번호는 어떤 형태로도 기기에 평문 저장하지 않는다)

  static String _generateSessionToken() {
    final rand = Random.secure();
    return List.generate(
      32,
      (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<void> _persistSession(Map<String, dynamic> user) async {
    final token = _generateSessionToken();
    await _dbHelper.setSessionToken(user['id'] as int, token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', user['username'] as String);
    await prefs.setString('session_token', token);
    // 구버전이 저장했던 평문 비밀번호 제거
    await prefs.remove('password');
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('username');
    final String? token = prefs.getString('session_token');
    final String? legacyPassword = prefs.getString('password');

    Map<String, dynamic>? user;
    if (username != null && token != null) {
      user = await _dbHelper.getUserBySessionToken(username, token);
    } else if (username != null && legacyPassword != null) {
      // 구버전(평문 저장) 세션 → 검증 후 토큰 방식으로 이전
      user = await _dbHelper.getUser(username, legacyPassword);
    }

    if (user != null) {
      _currentUser = user;
      if (token == null) await _persistSession(user);
      await _dbHelper.recordDauIfNeeded(user['id'] as int);
      await _loadUserDataFromDB();
      debugPrint('Auto-login success for: $username');
    } else if (username != null) {
      debugPrint('Auto-login failed: session invalid');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final user = await _dbHelper.getUser(username, password);
    if (user != null) {
      _currentUser = user;
      await _persistSession(user);
      await _dbHelper.recordDauIfNeeded(user['id'] as int);
      await _loadUserDataFromDB();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(
    String username,
    String name,
    String password,
    String goal,
    int age,
    double weight, {
    String? bloodType,
    String? medications,
    String? emergencyContact,
  }) async {
    try {
      await _dbHelper.insertUser({
        'username': username,
        'name': name.isNotEmpty ? name : username,
        'password': password,
        'goal': goal,
        'age': age,
        'weight': weight,
        'has_completed_onboarding': 0,
        'pedometer_enabled': 0,
        if (bloodType != null && bloodType.isNotEmpty) 'blood_type': bloodType,
        if (medications != null && medications.isNotEmpty) 'medications': medications,
        if (emergencyContact != null && emergencyContact.isNotEmpty)
          'emergency_contact': emergencyContact,
      });
      return await login(username, password);
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final userId = _currentUser?['id'] as int?;
    _currentUser = null;
    if (userId != null) {
      // 서버(로컬 DB) 측 세션 토큰 무효화
      await _dbHelper.setSessionToken(userId, null);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('session_token');
    notifyListeners();
  }

  Future<void> _loadUserDataFromDB() async {
    if (_currentUser == null) return;

    // Refresh current user data from DB to get latest
    final user = await _dbHelper.getUserById(_currentUser!['id'] as int);
    if (user != null) {
      _currentUser = user;
    }

    // Load personal data
    _age = _currentUser!['age'];
    _weight = _currentUser!['weight'];
    _bloodType = _currentUser!['blood_type'];
    _medications = _currentUser!['medications'];
    _emergencyContact = _currentUser!['emergency_contact'];
    _pedometerEnabled = (_currentUser!['pedometer_enabled'] ?? 0) == 1;

    // Load latest scores
    final scores = await _dbHelper.getLatestScores(_currentUser!['id']);
    // Reset local scores before loading
    _calculationScore = 0;
    _logicScore = 0;
    _memoryScore = 0;
    _attentionScore = 0;
    _voiceScore = 0;
    
    for (var score in scores) {
      setCognitiveScore(score['category'], score['score'], persist: false);
    }
    notifyListeners();
  }

  Future<void> updateUsername(String newUsername) async {
    if (_currentUser == null) return;
    await _dbHelper.updateUserField(_currentUser!['id'], 'username', newUsername);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
    await _loadUserDataFromDB();
  }

  Future<void> updateName(String newName) async {
    if (_currentUser == null) return;
    await _dbHelper.updateUserField(_currentUser!['id'], 'name', newName);
    await _loadUserDataFromDB();
  }

  Future<void> updateMedicalInfo({
    String? bloodType,
    String? medications,
    String? emergencyContact,
    int? age,
    double? weight,
  }) async {
    if (_currentUser == null) return;
    final userId = _currentUser!['id'];

    if (bloodType != null) await _dbHelper.updateUserField(userId, 'blood_type', bloodType);
    if (medications != null) await _dbHelper.updateUserField(userId, 'medications', medications);
    if (emergencyContact != null) await _dbHelper.updateUserField(userId, 'emergency_contact', emergencyContact);
    if (age != null) await _dbHelper.updateUserField(userId, 'age', age);
    if (weight != null) await _dbHelper.updateUserField(userId, 'weight', weight);

    await _loadUserDataFromDB();
  }

  Future<void> resetMeasurementData() async {
    if (_currentUser == null) return;
    await _dbHelper.resetUserMeasurementData(_currentUser!['id']);
    await _loadUserDataFromDB();
  }

  Future<void> setAge(int age) async {
    await updateMedicalInfo(age: age);
  }

  Future<void> setWeight(double weight) async {
    await updateMedicalInfo(weight: weight);
  }

  Future<void> setPedometerEnabled(bool enabled) async {
    if (_currentUser == null) return;
    _pedometerEnabled = enabled;
    await _dbHelper.updateUserField(_currentUser!['id'], 'pedometer_enabled', enabled ? 1 : 0);
    notifyListeners();
  }

  /// 동의 → 온보딩 → 초기 평가를 마친 시점에 호출.
  /// 이후 라우터가 온보딩 플로우로 리다이렉트하지 않는다.
  Future<void> completeOnboarding() async {
    if (_currentUser == null) return;
    await _dbHelper.updateUserOnboarding(_currentUser!['id'] as int, true);
    await _loadUserDataFromDB();
  }

  // --- Other Methods ---
  void setConsent(bool value) {
    _hasConsent = value;
    notifyListeners();
  }

  void setGoal(OnboardingGoal goal) {
    _goal = goal;
    notifyListeners();
  }

  void setSurveyAnswer(int questionIndex, int answer) {
    _surveyAnswers[questionIndex] = answer;
    notifyListeners();
  }

  void setCognitiveScore(String category, double score, {bool persist = true}) {
    switch (category) {
      case 'calculation': _calculationScore = score; break;
      case 'logic': _logicScore = score; break;
      case 'memory': _memoryScore = score; break;
      case 'attention': _attentionScore = score; break;
      case 'voice': _voiceScore = score; break;
    }
    
    if (persist && _currentUser != null) {
      _dbHelper.insertScore(_currentUser!['id'], category, score);
    }
    notifyListeners();
  }

  /// 초기 평가 위험도 (0.0 = 양호 ~ 1.0 = 위험)
  ///
  /// - 설문: "예"(1) 응답 비율이 높을수록 위험
  /// - 인지 과제: 점수(0-100)가 낮을수록 위험 → (1 - 평균/100)로 방향 반전
  /// - 측정된 인지 영역이 하나도 없으면 설문 결과만 사용
  double get totalAssessmentScore {
    final double surveyRisk = _surveyAnswers.isEmpty
        ? 0.0
        : _surveyAnswers.values.fold<int>(0, (sum, val) => sum + val) /
            _surveyAnswers.length;

    final measured = [
      _calculationScore,
      _logicScore,
      _memoryScore,
      _attentionScore,
    ].where((s) => s > 0).toList();

    if (measured.isEmpty) return surveyRisk.clamp(0.0, 1.0);

    final double cognitiveRisk =
        1.0 - (measured.reduce((a, b) => a + b) / measured.length) / 100.0;
    return ((surveyRisk + cognitiveRisk) / 2.0).clamp(0.0, 1.0);
  }
}
