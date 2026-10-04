import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 활동량 이상 알림을 눌렀을 때 보낼 문자 (LAUNCH_AUDIT P0-04).
const guardianAlertSmsBody = '오늘 활동량이 평소보다 많이 줄었어요. 시간 될 때 안부 연락 부탁해요.';

Uri guardianAlertSmsUri(String number) =>
    Uri.parse('sms:${Uri.encodeComponent(number)}?body=${Uri.encodeComponent(guardianAlertSmsBody)}');

/// 누구에게 무슨 문자를 보낼지 먼저 보여 주고, 사용자가 확인하면 문자 앱을 연다.
/// 앱이 직접 문자를 보내지 않는다. 번호는 알림에 싣지 않고 현재 사용자 정보에서 읽는다.
Future<void> showGuardianAlertSmsDialog(
  BuildContext context, {
  required String? phone,
  Future<bool> Function(Uri uri)? launch,
}) {
  final number = phone?.trim() ?? '';
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      if (number.isEmpty) {
        return AlertDialog(
          title: const Text('보호자에게 문자 보내기'),
          content: const Text('등록된 비상 연락처가 없습니다. 내 정보의 정보 수정에서 비상 연락처를 등록해 주세요.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('확인')),
          ],
        );
      }
      return AlertDialog(
        title: const Text('보호자에게 문자 보내기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('받는 사람: $number'),
            const SizedBox(height: 8),
            const Text('내용: $guardianAlertSmsBody'),
            const SizedBox(height: 12),
            const Text('문자 앱이 열리면 내용을 확인한 뒤 직접 보내 주세요.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('닫기')),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await (launch ?? launchUrl)(guardianAlertSmsUri(number));
            },
            child: const Text('문자 앱 열기'),
          ),
        ],
      );
    },
  );
}
