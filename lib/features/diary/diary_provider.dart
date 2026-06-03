import 'package:flutter/foundation.dart';
import '../../core/database_helper.dart';

class DiaryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  final Set<String> _markedDates = {};
  String? _selectedContent;
  List<Map<String, dynamic>> _allDiaries = [];
  bool _isSaving = false;

  Set<String> get markedDates => _markedDates;
  String? get selectedContent => _selectedContent;
  List<Map<String, dynamic>> get allDiaries => _allDiaries;
  bool get isSaving => _isSaving;

  bool hasEntry(DateTime day) {
    final key = _dateKey(day);
    return _markedDates.contains(key);
  }

  Future<void> loadMonth(int userId, DateTime month) async {
    final yearMonth =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final dates = await _db.getDiaryDatesForMonth(userId, yearMonth);
    _markedDates.clear();
    _markedDates.addAll(dates);
    notifyListeners();
  }

  Future<void> loadEntry(int userId, DateTime date) async {
    final row = await _db.getDiary(userId, _dateKey(date));
    _selectedContent = row?['content'] as String?;
    notifyListeners();
  }

  Future<bool> saveDiary(int userId, DateTime date, String content) async {
    if (content.trim().isEmpty) return false;
    _isSaving = true;
    notifyListeners();
    try {
      final key = _dateKey(date);
      await _db.upsertDiary(userId, key, content.trim());
      _markedDates.add(key);
      _selectedContent = content.trim();
      await _db.deleteOldDiaries(userId);
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> loadAllDiaries(int userId) async {
    _allDiaries = await _db.getAllDiaries(userId);
    notifyListeners();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
