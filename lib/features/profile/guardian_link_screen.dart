import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';
// import '../gait_analysis/pedometer_manager.dart'; // 제거됨

class GuardianLinkScreen extends StatelessWidget {
  const GuardianLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();
    // final pedometer = context.watch<PedometerManager>(); // 미사용 제거
    
    // 보호자용 대시보드 URL (데모용 가상 URL)
    final userId = user.currentUser?['id'] ?? 0;
    final dashboardUrl = 'https://memorylink.app/dashboard/view?id=$userId';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('보호자 안심 연결'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.security, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            const Text(
              '보호자님께 안심을 선물하세요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '아래 QR 코드를 보호자의 스마트폰으로 스캔하면,\n앱 설치 없이도 어르신의 활동 상태를 확인할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 48),
            
            // QR 코드 영역
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, // QR 코드는 흰색 배경 유지 (스캐너 호환성)
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: theme.brightness == Brightness.light ? 0.1 : 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: QrImageView(
                data: dashboardUrl,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: theme.colorScheme.primary),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // 정보 공유 안내
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  _InfoRow(icon: Icons.check, text: '실시간 걸음 수 및 활동 여부'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.check, text: '최근 인지 훈련 수행 결과'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.check, text: '긴급 상황 발생 시 알림 수신'),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            const SizedBox(height: 24),

            // 직접 연락 버튼 영역 (전화/문자)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final phone = user.emergencyContact ?? '';
                      if (phone.isNotEmpty) {
                        final url = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      }
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('보호자 전화'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final phone = user.emergencyContact ?? '';
                      if (phone.isNotEmpty) {
                        final String message = 'MemoryLink 알림: ${user.currentUser?['username'] ?? '어르신'}님이 현재 건강 리포트를 보냈습니다. 확인 부탁드립니다. \n$dashboardUrl';
                        final url = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      }
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('문자 알림'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            
            // 공유 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share(
                    '어르신의 인지 건강 상태를 확인할 수 있는 안심 링크입니다.\n$dashboardUrl',
                    subject: 'MemoryLink 보호자 안심 연결',
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('리포트 링크 공유하기 (카톡 등)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface)),
      ],
    );
  }
}
