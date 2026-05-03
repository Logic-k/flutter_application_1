import 'supabase_client.dart';

class CsService {
  static final _client = SupabaseManager.client;

  // 공지사항
  static Future<List<Map<String, dynamic>>> fetchNotices() async {
    final res = await _client
        .from('notices')
        .select()
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<Map<String, dynamic>?> fetchNoticeById(int id) async {
    final res = await _client
        .from('notices')
        .select()
        .eq('id', id)
        .maybeSingle();
    return res;
  }

  // FAQ
  static Future<List<Map<String, dynamic>>> fetchFaqs() async {
    final res = await _client
        .from('faqs')
        .select()
        .order('category')
        .order('sort_order');
    return List<Map<String, dynamic>>.from(res);
  }

  // 1:1 문의
  static Future<void> submitInquiry({
    required String username,
    required String title,
    required String body,
  }) async {
    await _client.from('inquiries').insert({
      'username': username,
      'title': title,
      'body': body,
    });
  }

  static Future<List<Map<String, dynamic>>> fetchMyInquiries(
      String username) async {
    final res = await _client
        .from('inquiries')
        .select()
        .eq('username', username)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<Map<String, dynamic>?> fetchInquiryDetail(int id) async {
    final inquiry = await _client
        .from('inquiries')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (inquiry == null) return null;

    final replies = await _client
        .from('inquiry_replies')
        .select()
        .eq('inquiry_id', id)
        .order('created_at')
        .limit(1);

    return {
      ...inquiry,
      'reply': replies.isNotEmpty ? replies.first : null,
    };
  }

  // 관리자 전용 — CS 관리
  static Future<void> createNotice({
    required String title,
    required String body,
    bool isPinned = false,
  }) async {
    await _client.from('notices').insert({
      'title': title,
      'body': body,
      'is_pinned': isPinned,
    });
  }

  static Future<void> updateNotice(
    int id, {
    required String title,
    required String body,
    required bool isPinned,
  }) async {
    await _client.from('notices').update({
      'title': title,
      'body': body,
      'is_pinned': isPinned,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> deleteNotice(int id) async {
    await _client.from('notices').delete().eq('id', id);
  }

  static Future<void> createFaq({
    required String category,
    required String question,
    required String answer,
    int sortOrder = 0,
  }) async {
    await _client.from('faqs').insert({
      'category': category,
      'question': question,
      'answer': answer,
      'sort_order': sortOrder,
    });
  }

  static Future<void> updateFaq(
    int id, {
    required String category,
    required String question,
    required String answer,
  }) async {
    await _client.from('faqs').update({
      'category': category,
      'question': question,
      'answer': answer,
    }).eq('id', id);
  }

  static Future<void> deleteFaq(int id) async {
    await _client.from('faqs').delete().eq('id', id);
  }

  static Future<List<Map<String, dynamic>>> fetchAllInquiries() async {
    final res = await _client
        .from('inquiries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> replyToInquiry({
    required int inquiryId,
    required String body,
  }) async {
    await _client.from('inquiry_replies').insert({
      'inquiry_id': inquiryId,
      'body': body,
    });
    await _client
        .from('inquiries')
        .update({'status': 'answered'}).eq('id', inquiryId);
  }
}
