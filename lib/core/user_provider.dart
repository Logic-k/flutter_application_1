import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

enum OnboardingGoal { prevention, concern, family }

class UserProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
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

  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get hasConsent => _hasConsent;
  OnboardingGoal? get goal => _goal;
  
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

  // --- Auth Methods ---
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('username');
    final String? password = prefs.getString('password');

    if (username != null && password != null) {
      final user = await _dbHelper.getUser(username, password);
      if (user != null) {
        _currentUser = user;
        await _dbHelper.recordDauIfNeeded(user['id'] as int);
        await _loadUserDataFromDB();
        debugPrint('Auto-login success for: $username');
      } else {
        debugPrint('Auto-login failed: User not found in DB');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final user = await _dbHelper.getUser(username, password);
    if (user != null) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      await _dbHelper.recordDauIfNeeded(user['id'] as int);
      await _loadUserDataFromDB();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password, String goal, int age, double weight) async {
    try {
      await _dbHelper.insertUser({
        'username': username,
        'password': password,
        'goal': goal,
        'age': age,
        'weight': weight,
        'has_completed_onboarding': 0,
        'pedometer_enabled': 0,
      });
      return await login(username, password);
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    notifyListeners();
  }

  Future<void> _loadUserDataFromDB() async {
    if (_currentUser == null) return;
    
    // Refresh current user data from DB to get latest
    final user = await _dbHelper.getUser(_currentUser!['username'], _currentUser!['password']);
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
    
    for (var score in scores) {
      setCognitiveScore(score['category'], score['score'], persist: false);
    }
    notifyListeners();
  }

  Future<void> updateUsername(String newName) async {
    if (_currentUser == null) return;
    await _dbHelper.updateUserField(_currentUser!['id'], 'username', newName);
    
    // Update local prefs as well
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName);
    
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
    }
    
    if (persist && _currentUser != null) {
      _dbHelper.insertScore(_currentUser!['id'], category, score);
    }
    notifyListeners();
  }

  double get totalAssessmentScore {
    double surveyScore = _surveyAnswers.isEmpty 
        ? 0 
        : _surveyAnswers.values.fold(0, (sum, val) => sum + val) / 10.0;
    double cognitiveAvg = (_calculationScore + _logicScore + _memoryScore + _attentionScore) / 4.0;
    return (surveyScore + cognitiveAvg) / 2.0;
  }
}
