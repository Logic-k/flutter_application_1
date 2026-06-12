import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class CsService {
  static FirebaseFirestore get _db => FirebaseService.db;

  static Map<String, dynamic> _docToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'id': doc.id,
      ...data.map((key, value) {
        if (value is Timestamp) {
          return MapEntry(key, value.toDate().toIso8601String());
        }
        return MapEntry(key, value);
      }),
    };
  }

  // 공지사항
  static Future<List<Map<String, dynamic>>> fetchNotices() async {
    try {
      final snapshot = await _db
          .collection('notices')
          .orderBy('created_at', descending: true)
          .get();
      final docs = snapshot.docs.map(_docToMap).toList();
      // 고정 공지 우선 정렬 (복합 인덱스 없이 메모리 정렬)
      docs.sort((a, b) {
        final aPinned = a['is_pinned'] == true ? 0 : 1;
        final bPinned = b['is_pinned'] == true ? 0 : 1;
        return aPinned.compareTo(bPinned);
      });
      return docs;
    } catch (e) {
      debugPrint('fetchNotices error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchNoticeById(String id) async {
    try {
      final doc = await _db.collection('notices').doc(id).get();
      if (!doc.exists) return null;
      return _docToMap(doc);
    } catch (e) {
      debugPrint('fetchNoticeById error: $e');
      return null;
    }
  }

  // FAQ
  static Future<List<Map<String, dynamic>>> fetchFaqs() async {
    try {
      final snapshot = await _db.collection('faqs').get();
      final docs = snapshot.docs.map(_docToMap).toList();
      // 카테고리 → sort_order 순 정렬 (복합 인덱스 없이 메모리 정렬)
      docs.sort((a, b) {
        final catCompare = (a['category'] as String? ?? '')
            .compareTo(b['category'] as String? ?? '');
        if (catCompare != 0) return catCompare;
        return ((a['sort_order'] as int?) ?? 0)
            .compareTo((b['sort_order'] as int?) ?? 0);
      });
      return docs;
    } catch (e) {
      debugPrint('fetchFaqs error: $e');
      return [];
    }
  }

  // 1:1 문의
  static Future<void> submitInquiry({
    required String username,
    required String title,
    required String body,
  }) async {
    await _db.collection('inquiries').add({
      'username': username,
      'title': title,
      'body': body,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> fetchMyInquiries(
      String username) async {
    try {
      final snapshot = await _db
          .collection('inquiries')
          .where('username', isEqualTo: username)
          .get();
      final docs = snapshot.docs.map(_docToMap).toList();
      docs.sort((a, b) =>
          (b['created_at'] as String? ?? '').compareTo(a['created_at'] as String? ?? ''));
      return docs;
    } catch (e) {
      debugPrint('fetchMyInquiries error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchInquiryDetail(String id) async {
    try {
      final doc = await _db.collection('inquiries').doc(id).get();
      if (!doc.exists) return null;

      final replies = await _db
          .collection('inquiries')
          .doc(id)
          .collection('replies')
          .orderBy('created_at')
          .limit(1)
          .get();

      return {
        ..._docToMap(doc),
        'reply': replies.docs.isNotEmpty
            ? _docToMap(replies.docs.first)
            : null,
      };
    } catch (e) {
      debugPrint('fetchInquiryDetail error: $e');
      return null;
    }
  }

  // 관리자 전용 — CS 관리
  static Future<void> createNotice({
    required String title,
    required String body,
    bool isPinned = false,
  }) async {
    await _db.collection('notices').add({
      'title': title,
      'body': body,
      'is_pinned': isPinned,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateNotice(
    String id, {
    required String title,
    required String body,
    required bool isPinned,
  }) async {
    await _db.collection('notices').doc(id).update({
      'title': title,
      'body': body,
      'is_pinned': isPinned,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteNotice(String id) async {
    await _db.collection('notices').doc(id).delete();
  }

  static Future<void> createFaq({
    required String category,
    required String question,
    required String answer,
    int sortOrder = 0,
  }) async {
    await _db.collection('faqs').add({
      'category': category,
      'question': question,
      'answer': answer,
      'sort_order': sortOrder,
    });
  }

  static Future<void> updateFaq(
    String id, {
    required String category,
    required String question,
    required String answer,
  }) async {
    await _db.collection('faqs').doc(id).update({
      'category': category,
      'question': question,
      'answer': answer,
    });
  }

  static Future<void> deleteFaq(String id) async {
    await _db.collection('faqs').doc(id).delete();
  }

  static Future<List<Map<String, dynamic>>> fetchAllInquiries() async {
    try {
      final snapshot = await _db
          .collection('inquiries')
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.map(_docToMap).toList();
    } catch (e) {
      debugPrint('fetchAllInquiries error: $e');
      return [];
    }
  }

  static Future<void> replyToInquiry({
    required String inquiryId,
    required String body,
  }) async {
    final batch = _db.batch();
    final replyRef = _db
        .collection('inquiries')
        .doc(inquiryId)
        .collection('replies')
        .doc();
    batch.set(replyRef, {
      'body': body,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('inquiries').doc(inquiryId), {
      'status': 'answered',
    });
    await batch.commit();
  }

  // 데모용 초기 공지사항/FAQ 시드 (이미 데이터가 있으면 건너뜀)
  static Future<void> seedDemoData() async {
    try {
      final existing = await _db.collection('notices').limit(1).get();
      if (existing.docs.isNotEmpty) return;

      final batch = _db.batch();

      // ── 공지사항 3개 ────────────────────────────────────────────
      final notices = [
        {
          'title': '[필독] MemoryLink 서비스 이용 안내',
          'body':
              'MemoryLink를 이용해 주셔서 감사합니다.\n\n'
              '본 앱은 어르신들의 인지 건강을 지원하기 위해 설계된 디지털 헬스케어 서비스입니다.\n\n'
              '주요 기능 안내:\n'
              '• 인지 훈련: 기억력·계산력·논리력·집중력 게임으로 매일 뇌를 운동하세요.\n'
              '• AI 챗봇: 자연스러운 대화를 통해 인지 상태를 부드럽게 확인합니다.\n'
              '• 기억의 정원: 오늘의 일상을 일기로 기록하고 과거 기억을 돌아보세요.\n'
              '• 걷기 분석: 일일 걸음수와 보행 패턴을 추적하여 신체 건강을 관리합니다.\n'
              '• 임상 리포트: 보호자·임상의와 공유할 수 있는 전문 리포트를 생성합니다.\n\n'
              '궁금한 점은 고객센터 > 1:1 문의를 이용해 주세요.',
          'is_pinned': true,
        },
        {
          'title': 'AI 챗봇 업데이트 완료 (v1.2)',
          'body':
              'AI 챗봇이 더욱 자연스럽고 따뜻하게 업데이트되었습니다.\n\n'
              '주요 개선 사항:\n'
              '• 한국어 자연대화 품질 향상 — 어르신 어투에 맞춘 친근한 응답\n'
              '• 응답 속도 약 30% 개선\n'
              '• 대화 도중 인지 점수 분석 정확도 향상\n'
              '• 네트워크 불안정 시 자동 오프라인 모드 전환 기능 추가\n\n'
              '새로워진 AI 챗봇을 지금 바로 이용해 보세요!',
          'is_pinned': false,
        },
        {
          'title': '개인정보 처리방침 개정 안내 (2026.06.01)',
          'body':
              '2026년 6월 1일부로 개인정보 처리방침이 일부 개정되었습니다.\n\n'
              '주요 변경 내용:\n'
              '• 건강 정보 보관 기간 명확화 (최대 3년, 탈퇴 시 즉시 삭제)\n'
              '• 보호자 공유 데이터 범위 명시 (걸음수, 인지 점수 요약)\n'
              '• 제3자 제공 항목 업데이트 (임상 연구 기관 제외)\n\n'
              '전문은 프로필 > 앱 설정 > 개인정보 처리방침에서 확인하실 수 있습니다.\n'
              '변경 내용에 동의하지 않으실 경우 고객센터로 문의해 주세요.',
          'is_pinned': false,
        },
      ];
      for (final notice in notices) {
        batch.set(_db.collection('notices').doc(), {
          ...notice,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // ── FAQ 8개 ──────────────────────────────────────────────────
      final faqs = [
        {
          'category': '계정',
          'question': '처음 가입은 어떻게 하나요?',
          'answer':
              '앱 실행 후 로그인 화면에서 "회원가입" 버튼을 누르세요.\n'
              '사용자 이름(영문/숫자)과 비밀번호를 설정한 뒤 기본 건강 정보를 입력하면 가입이 완료됩니다.\n'
              '가입 후 처음 실행 시 앱 사용법을 안내하는 온보딩 화면이 표시됩니다.',
          'sort_order': 0,
        },
        {
          'category': '계정',
          'question': '비밀번호를 잊어버렸어요. 어떻게 하나요?',
          'answer':
              '현재 버전에서는 비밀번호를 재설정하려면 고객센터 > 1:1 문의를 통해 요청해 주세요.\n'
              '본인 확인 후 관리자가 임시 비밀번호를 발급해 드립니다.\n'
              '추후 업데이트에서 이메일 인증 기반 비밀번호 찾기 기능이 추가될 예정입니다.',
          'sort_order': 1,
        },
        {
          'category': '훈련',
          'question': '훈련 게임은 어떤 종류가 있나요?',
          'answer':
              '총 7가지 인지 훈련 게임이 제공됩니다.\n\n'
              '• 누가 큰가요 — 두 수식을 비교하는 계산·판단력 게임\n'
              '• 구구단 맞추기 — 곱셈 결과를 맞추는 계산력 게임\n'
              '• 규칙 찾아보기 — 숫자 수열의 규칙을 찾는 논리 게임\n'
              '• 그림 스도쿠 — 3×3 그리드에 도형을 채우는 기억·지각 게임\n'
              '• 범주화 게임 — 사물을 올바른 범주로 분류하는 게임\n'
              '• 같은 모양 찾기 — 짝이 맞는 도형을 찾는 집중력 게임\n'
              '• 일상 회상 훈련 — 오늘 하루를 떠올려 보는 서술형 활동',
          'sort_order': 0,
        },
        {
          'category': '훈련',
          'question': '인지 점수는 어떻게 계산되나요?',
          'answer':
              '각 게임 완료 시 정답률을 기반으로 0~100점 사이의 인지 점수가 산출됩니다.\n\n'
              '영역별 점수 의미:\n'
              '• 75점 이상: 정상 범위\n'
              '• 55~74점: 경계선 (꾸준한 훈련 권장)\n'
              '• 35~54점: 경과 관찰 (전문가 상담 고려)\n'
              '• 34점 이하: 전문의 의뢰 권장\n\n'
              '점수는 리포트 탭에서 추이 차트로 확인할 수 있습니다.',
          'sort_order': 1,
        },
        {
          'category': '보행',
          'question': '걸음수 측정이 부정확한 것 같아요.',
          'answer':
              '걸음수는 스마트폰 내장 가속도 센서를 활용해 측정합니다.\n\n'
              '정확도를 높이려면:\n'
              '• 폰을 주머니나 허리 벨트에 고정해 주세요.\n'
              '• 앱 배터리 최적화 예외 설정을 허용해 주세요 (설정 > 앱 > 배터리).\n'
              '• 백그라운드 실행이 허용되어야 종일 추적이 가능합니다.\n\n'
              '측정값은 만보기 전용 기기와 최대 ±5% 오차가 있을 수 있습니다.',
          'sort_order': 0,
        },
        {
          'category': '보행',
          'question': '보행 정밀 분석은 무엇인가요?',
          'answer':
              '보행 정밀 분석은 약 3분간 걷는 동안 스마트폰 센서로 보행 리듬과 안정성을 측정하는 기능입니다.\n\n'
              '측정 항목:\n'
              '• 보행 안정성 지수 (0~100%)\n'
              '• 이중 과제(dual-task) 수행 능력 — 걸으면서 인지 과제를 동시에 처리하는 능력\n\n'
              '걷기 대시보드 > 보행 정밀 분석 버튼을 눌러 시작할 수 있습니다.\n'
              '결과는 임상 리포트에 자동 반영됩니다.',
          'sort_order': 1,
        },
        {
          'category': '기타',
          'question': '임상 리포트를 보호자나 의사에게 전달하려면?',
          'answer':
              '리포트 탭 하단의 "임상 리포트 생성" 버튼을 누르면 4단계 설정을 거쳐 PDF 리포트가 생성됩니다.\n\n'
              '생성 후 "공유" 버튼을 눌러 다음 방법으로 전달하실 수 있습니다:\n'
              '• 카카오톡, 문자 메시지로 파일 첨부 전송\n'
              '• 이메일에 PDF 첨부\n'
              '• 병원 방문 시 스마트폰 화면으로 직접 제시\n\n'
              '리포트에는 최근 30일 인지 점수 추이, MMSE 환산값, 보행 데이터가 포함됩니다.',
          'sort_order': 0,
        },
        {
          'category': '기타',
          'question': '보호자 안심 연결 기능이란 무엇인가요?',
          'answer':
              '보호자 안심 연결은 가족이나 보호자가 어르신의 건강 현황을 실시간으로 확인할 수 있는 기능입니다.\n\n'
              '사용 방법:\n'
              '1. 프로필 > 보호자 안심 연결에서 QR 코드를 생성합니다.\n'
              '2. 보호자가 QR 코드를 스캔하면 전용 모니터링 대시보드에 접속됩니다.\n'
              '3. 대시보드에서 오늘 걸음수, 주간 훈련 점수, 이상 징후 알림을 확인할 수 있습니다.\n\n'
              '공유되는 정보는 요약 수치만 포함되며, 일기 내용은 공유되지 않습니다.',
          'sort_order': 1,
        },
      ];

      for (final faq in faqs) {
        final ref = _db.collection('faqs').doc();
        batch.set(ref, faq);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('seedDemoData error: $e');
    }
  }
}
