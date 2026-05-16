import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/core/database_helper.dart';
import 'package:flutter_application_1/core/user_provider.dart';
import 'package:flutter_application_1/core/settings_provider.dart';

// --- Core Mocks ---
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockUserProvider extends Mock implements UserProvider {}

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

// --- Supabase Fake ---
// Returns null/empty for all calls so try/catch blocks in providers handle it gracefully.
class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  SupabaseQueryBuilder from(String table) => _FakeQueryBuilder();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #maybeSingle) return Future<Map<String, dynamic>?>.value(null);
    if (name == #upsert) return Future<dynamic>.value([]);
    return _FakeFilterBuilder();
  }
}

class _FakeFilterBuilder extends Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #maybeSingle) return Future<Map<String, dynamic>?>.value(null);
    return this;
  }
}
