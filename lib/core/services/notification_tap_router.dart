import 'package:flutter/foundation.dart';

/// 알림을 눌렀을 때 할 일을 앱 화면 쪽으로 넘긴다 (LAUNCH_AUDIT P0-04).
///
/// 알림 payload에는 전화번호 같은 개인정보를 넣지 않고 종류만 넣는다. 실제 처리는
/// 앱이 화면을 그린 뒤 현재 로그인 사용자 정보로 한다(main.dart).
class NotificationTapRouter {
  NotificationTapRouter._();

  /// 활동량 이상 알림: 보호자에게 보낼 문자를 확인하는 창을 연다.
  static const guardianAlertPayload = 'guardian_alert';

  static final ValueNotifier<String?> pending = ValueNotifier<String?>(null);

  static void handle(String? payload) {
    if (payload == null || payload.isEmpty) return;
    pending.value = payload;
  }

  /// 기다리는 탭을 꺼내고 비운다.
  static String? take() {
    final payload = pending.value;
    pending.value = null;
    return payload;
  }
}
