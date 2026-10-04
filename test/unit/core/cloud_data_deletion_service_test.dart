import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_application_1/core/services/cloud_data_deletion_service.dart';
import 'package:flutter_application_1/core/services/guardian_sync_service.dart';
import '../../helpers/mock_definitions.dart';

class _Guardian extends Mock implements GuardianSyncService {}

void main() {
  test('서버에 연결할 수 없으면 아무것도 지우지 않고 실패를 알린다', () async {
    final guardian = _Guardian();
    final service = CloudDataDeletionService(
      guardian: guardian,
      db: MockDatabaseHelper(),
      uidProvider: () => null,
      firebaseAvailable: () => false,
    );

    final result = await service.deleteFor(userId: 1, username: 'Synthetic user');

    expect(result.success, isFalse);
    expect(result.failed, ['서버 연결']);
    verifyNever(() => guardian.deleteCloudData(any()));
  });
}
