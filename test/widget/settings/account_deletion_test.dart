import 'package:flutter_application_1/core/services/account_deletion_service.dart';
import 'package:flutter_application_1/core/services/cloud_data_deletion_service.dart';
import 'package:flutter_application_1/features/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_definitions.dart';
import '../../helpers/test_helpers.dart';

class _FakeAccountDeletion extends AccountDeletionService {
  _FakeAccountDeletion(this.status)
      : super(deleteCloud: ({required int userId, required String username}) async => const CloudDeletionResult([]));

  final AccountDeletionStatus status;
  final calls = <String>[];

  @override
  Future<AccountDeletionResult> deleteAccount({
    required int userId,
    required String username,
    Future<void> Function()? stopTracking,
  }) async {
    calls.add('$userId:$username');
    return AccountDeletionResult(status,
        failed: status == AccountDeletionStatus.cloudFailed ? const ['서버 연결'] : const []);
  }
}

/// 설정의 '계정과 모든 데이터 삭제'는 두 번 확인하고, 서버 기록을 못 지우면 아무것도 지우지 않는다(LAUNCH_AUDIT P0-07).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<MockUserProvider> pumpSettings(WidgetTester tester, _FakeAccountDeletion deletion) async {
    final user = MockUserProvider();
    when(() => user.currentUser).thenReturn({'id': 7, 'username': 'kim'});
    when(() => user.logout()).thenAnswer((_) async {});
    await pumpWithProviders(tester, SettingsScreen(accountDeletion: deletion), userProvider: user);
    await tester.pump();
    final row = find.text('계정과 모든 데이터 삭제');
    await tester.ensureVisible(row);
    await tester.pump();
    await tester.tap(row);
    await tester.pumpAndSettle();
    return user;
  }

  Future<void> confirmTwice(WidgetTester tester) async {
    expect(find.text('계정과 모든 데이터를 지울까요?'), findsOneWidget);
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();
    expect(find.text('정말 지울까요?'), findsOneWidget);
    await tester.tap(find.text('모두 삭제'));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  testWidgets('두 번 확인한 뒤 지우고 로그아웃한다', (tester) async {
    final deletion = _FakeAccountDeletion(AccountDeletionStatus.deleted);
    final user = await pumpSettings(tester, deletion);
    await confirmTwice(tester);

    expect(deletion.calls, ['7:kim']);
    verify(() => user.logout()).called(1);
    expect(find.text('계정과 모든 데이터를 지웠습니다.'), findsOneWidget);
  });

  testWidgets('취소하면 아무것도 지우지 않는다', (tester) async {
    final deletion = _FakeAccountDeletion(AccountDeletionStatus.deleted);
    final user = await pumpSettings(tester, deletion);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(deletion.calls, isEmpty);
    verifyNever(() => user.logout());
  });

  testWidgets('서버 기록을 못 지우면 아무것도 지우지 않았다고 알리고 로그인을 유지한다', (tester) async {
    final deletion = _FakeAccountDeletion(AccountDeletionStatus.cloudFailed);
    final user = await pumpSettings(tester, deletion);
    await confirmTwice(tester);
    await tester.pumpAndSettle();

    expect(find.text('지우지 못했습니다'), findsOneWidget);
    expect(find.textContaining('아무것도 지우지 않았습니다'), findsOneWidget);
    verifyNever(() => user.logout());
  });
}
