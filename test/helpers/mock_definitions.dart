import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/core/database_helper.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/core/settings_provider.dart';
import 'package:flutter_application_1/features/diary/diary_provider.dart';
import 'package:flutter_application_1/features/gait_analysis/pedometer_manager.dart';
import 'package:flutter_application_1/features/training/difficulty_provider.dart';
import 'package:flutter_application_1/features/training/training_progress_provider.dart';

// --- Core Mocks ---
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockUserProvider extends Mock implements UserProvider {}

class MockPedometerManager extends Mock implements PedometerManager {}

class MockDifficultyProvider extends Mock implements DifficultyProvider {}

class MockTrainingProgressProvider extends Mock
    implements TrainingProgressProvider {}

class MockDiaryProvider extends Mock implements DiaryProvider {}

// --- Settings Fake (simpler than Mock for value-only providers) ---
class FakeSettingsProvider extends SettingsProvider {
  @override
  bool get voiceGuidanceEnabled => false;
  @override
  bool get hapticFeedbackEnabled => false;
  @override
  double get textScaleFactor => 1.0;
  @override
  AppFontSize get fontSize => AppFontSize.normal;
  // Overrides _loadSettings so SharedPreferences is never called
  @override
  Future<void> setFontSize(AppFontSize size) async {}
  @override
  Future<void> setVoiceGuidance(bool enabled) async {}
  @override
  Future<void> setHapticFeedback(bool enabled) async {}
}
