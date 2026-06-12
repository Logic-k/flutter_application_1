import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory _repositoryRoot() {
  var directory = Directory.current.absolute;
  while (!File(
    '${directory.path}${Platform.pathSeparator}pubspec.yaml',
  ).existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Flutter repository root could not be found.');
    }
    directory = parent;
  }
  return directory;
}

String _readDocument(Directory root, String relativePath) {
  final path = relativePath.split('/').fold(root.path, (current, segment) {
    return '$current${Platform.pathSeparator}$segment';
  });
  return File(path).readAsStringSync();
}

String? _readOptionalDocument(Directory root, String relativePath) {
  final path = relativePath.split('/').fold(root.path, (current, segment) {
    return '$current${Platform.pathSeparator}$segment';
  });
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : null;
}

void main() {
  final root = _repositoryRoot();
  final readme = _readDocument(root, 'README.md');
  final projectDocs = _readDocument(root, 'PROJECT_DOCS.md');
  final progress = _readDocument(root, 'PROGRESS.md');
  final capstone = _readDocument(root, 'capstone_project_plan_renewal.md');
  final portingGuide = _readOptionalDocument(
    root,
    'MemoryLInkApp_Design/flutter_port/PORTING_GUIDE.md',
  );

  // README는 랜딩페이지 형식으로 재작성되어 기술 상세 검증 대상에서 제외한다.
  // 기술적 사실은 PROJECT_DOCS.md와 PROGRESS.md가 책임진다.
  test('문서는 현재 아키텍처와 구현 상태를 정확히 설명한다', () {
    for (final document in [projectDocs, progress]) {
      expect(document, contains('로컬 SQLite 기반 인증'));
      expect(document, contains('규칙 기반 음성 지표(TTR/WPM) 구현'));
      expect(document, contains('4페이지 PDF 생성 구현'));
      expect(document, isNot(contains('Firebase 기반 로그인/회원가입')));
      expect(document, isNot(contains('렌더링/공유 연결 필요')));
    }
    expect(capstone, contains('연구·캡스톤 프로토타입'));
    expect(capstone, isNot(contains('미완성 항목: 온디바이스 LLM 음성 분석')));
  });

  test('문서는 QA 수치와 현재 실행 한계를 정확히 기록한다', () {
    for (final document in [projectDocs, progress]) {
      expect(document, contains('단위 테스트 63개'));
      expect(document, contains('위젯 테스트 36개'));
      expect(document, contains('통합 테스트 5개'));
      expect(document, isNot(contains('Maestro 11개')));
      expect(document, isNot(contains('Maestro QA 자동화 (11개 flow)')));
    }
    expect(projectDocs, contains('게이팅 Maestro flow 19개'));
    expect(projectDocs, contains('스크린샷 flow 1개'));
    expect(
      projectDocs,
      contains(
        '현재 `flutter analyze`, `flutter test`, `flutter build`는 green이 아니다',
      ),
    );
    // PROGRESS.md는 2026-06-08 Maestro 20/20 통과 이후의 최신 현황을 기록한다.
    expect(progress, contains('Maestro E2E flow 20개'));
    expect(progress, contains('green 아님'));
    expect(progress, contains('Android 에뮬레이터 없음'));
    expect(projectDocs, contains('Android 에뮬레이터 없음'));
    expect(
      progress,
      contains(
        '`lib/features/training_corrupted/training_hub_screen.dart`는 '
        '파일시스템 손상 상태',
      ),
    );
  });

  test('문서는 향후 개발 우선순위와 문서 역할을 구분한다', () {
    final roadmapDocs = '$readme\n$progress';
    final security = roadmapDocs.indexOf('P0 보안');
    final qaCi = roadmapDocs.indexOf('P0 QA/CI');
    final release = roadmapDocs.indexOf('P0 릴리스 기반');
    final mlExpansion = roadmapDocs.indexOf('ML 확장');

    expect(security, greaterThanOrEqualTo(0));
    expect(qaCi, greaterThanOrEqualTo(0));
    expect(release, greaterThanOrEqualTo(0));
    expect(mlExpansion, greaterThanOrEqualTo(0));
    expect(security, lessThan(mlExpansion));
    expect(qaCi, lessThan(mlExpansion));
    expect(release, lessThan(mlExpansion));

    expect(capstone, contains('현재 구현'));
    expect(capstone, contains('목표 아키텍처'));
    if (portingGuide != null) {
      expect(portingGuide, contains('역사적 포팅 가이드'));
      expect(portingGuide, contains('현재 상태'));
    }
  });
}
