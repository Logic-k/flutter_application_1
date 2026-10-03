import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/services/guardian_sync_service.dart';
import '../../helpers/mock_definitions.dart';

class _Firestore extends Mock implements FirebaseFirestore {}
// The SDK marks these interfaces sealed; these test-only SaaS mocks are not shipped.
// ignore: subtype_of_sealed_class
class _Collection extends Mock implements CollectionReference<Map<String, dynamic>> {}
// ignore: subtype_of_sealed_class
class _Document extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockDatabaseHelper db;
  late _Firestore firestore;
  late _Document document;
  late List<Map<String, dynamic>> writes;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = MockDatabaseHelper();
    firestore = _Firestore();
    final collection = _Collection();
    document = _Document();
    writes = [];
    when(() => db.getWeeklySteps(1)).thenAnswer((_) async => []);
    when(() => db.getScoreHistory(1)).thenAnswer((_) async => [
      {'category': 'memory', 'score': 72.0, 'created_at': '2026-10-03'},
    ]);
    when(() => firestore.collection('guardian_views')).thenReturn(collection);
    when(() => collection.doc(any())).thenReturn(document);
    when(() => document.set(any())).thenAnswer((call) async {
      writes.add(Map<String, dynamic>.from(call.positionalArguments.first as Map));
    });
    when(() => document.set(any(), any())).thenAnswer((call) async {
      writes.add(Map<String, dynamic>.from(call.positionalArguments.first as Map));
    });
  });
  GuardianSyncService service({String? uid = 'owner-a'}) => GuardianSyncService(
    db: db, firestore: firestore, uidProvider: () => uid,
  );

  test('service construction and local token work without Firebase', () async {
    expect(Firebase.apps, isEmpty);
    final service = GuardianSyncService(db: db);
    expect(await service.getOrCreateToken(1), hasLength(16));
    expect(Firebase.apps, isEmpty);
  });
  test('missing Firebase UID fails before local health reads or cloud writes', () async {
    final result = await service(uid: null).syncToFirestore(
      userId: 1, userName: 'Synthetic user', todaySteps: 5000,
    );
    expect(result.success, isFalse);
    expect(writes, isEmpty);
    verifyNever(() => db.getWeeklySteps(any()));
    verifyNever(() => db.getScoreHistory(any()));
  });
  test('missing UID cannot publish an anomaly', () async {
    final result = await service(uid: '').syncAnomalyAlert(
      userId: 1, userName: 'Synthetic user', todaySteps: 0, weeklyAvg: 5000,
    );
    expect(result, isFalse);
    expect(writes, isEmpty);
  });
  test('normal full sync omits contact and retains existing summary fields', () async {
    final result = await service().syncToFirestore(
      userId: 1, userName: 'Synthetic user', todaySteps: 5000,
      emergencyContact: '01000000000',
    );
    expect(result.success, isTrue);
    final payload = writes.single;
    expect(payload['ownerUid'], 'owner-a');
    expect(payload['is_anomaly'], isFalse);
    expect(payload.containsKey('emergency_contact'), isFalse);
    expect(payload['recent_scores'], hasLength(1));
    expect(payload['today_steps'], 5000);
  });
  test('normal sync does not update global user statistics', () async {
    expect((await service().syncToFirestore(
      userId: 1, userName: 'Synthetic user', todaySteps: 5000,
    )).success, isTrue);
    verifyNever(() => firestore.collection('global_stats'));
  });
  test('actual anomaly keeps the emergency contact and merge semantics', () async {
    expect(await service().syncAnomalyAlert(
      userId: 1, userName: 'Synthetic user', todaySteps: 0, weeklyAvg: 5000,
      emergencyContact: '01000000000',
    ), isTrue);
    expect(writes.single['is_anomaly'], isTrue);
    expect(writes.single['emergency_contact'], '01000000000');
    final captured = verify(() => document.set(any(), captureAny())).captured.single as SetOptions;
    expect(captured.merge, isTrue);
  });
}
