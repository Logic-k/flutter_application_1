import 'package:flutter_application_1/core/services/guardian_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Firebase.initializeApp()이 실패한 로컬 전용 모드(예: iOS에 GoogleService-Info.plist가
  // 없을 때)를 재현한다. 테스트 환경에서는 initializeApp을 부르지 않으므로
  // FirebaseFirestore.instance가 [core/no-app]을 던진다.
  test('로컬 전용 모드에서도 생성은 성공하고, 이상 알림 전송은 실패(false)로 보고한다', () async {
    final service = GuardianSyncService();

    final ok = await service.syncAnomalyAlert(
      userId: 1,
      userName: '테스트',
      todaySteps: 0,
      weeklyAvg: 8000,
    );

    expect(ok, isFalse);
  });

  test('로컬 전용 모드에서도 보호자 링크 토큰은 만들 수 있다', () async {
    final service = GuardianSyncService();

    final token = await service.getOrCreateToken(1);

    expect(token, hasLength(16));
    expect(service.guardianUrl(token), endsWith('token=$token'));
  });
}
