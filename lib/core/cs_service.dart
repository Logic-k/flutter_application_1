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
}
