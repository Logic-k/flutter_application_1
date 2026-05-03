import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  Future<void> _launchPhone(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전화를 걸 수 없습니다: $number')),
        );
      }
    }
  }

  Future<void> _launchMap(BuildContext context) async {
    // 치매안심센터 검색 (네이버 지도 또는 카카오맵)
    final uri = Uri.parse('https://map.naver.com/v5/search/%EC%B9%98%EB%A7%A4%EC%95%88%EC%8B%AC%EC%84%BC%ED%84%B0');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지도 앱을 열 수 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('기관 및 서비스 연계')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '더 자세한 도움이\n필요하신가요?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildCenterCard(
              context,
              theme,
              title: '중앙치매센터',
              description: '전국 어디서나 24시간 치매 상담 콜센터',
              actionText: '1899-9988 전화하기',
              actionIcon: Icons.call,
              onTap: () => _launchPhone(context, '18999988'),
            ),
            const SizedBox(height: 16),
            _buildCenterCard(
              context,
              theme,
              title: '지역 치매안심센터 안내',
              description: '가까운 보건소 내 치매 지원 서비스를 찾아보세요.',
              actionText: '가까운 센터 찾기',
              actionIcon: Icons.location_on,
              onTap: () => _launchMap(context),
            ),
            const SizedBox(height: 32),
            Text('우리 앱만의 통합 연계', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              theme,
              title: '리포트 자동 생성',
              description: '준비된 상담 자료를 의사에게 전달하세요.',
              icon: Icons.contact_mail,
              onTap: () => context.push('/'),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              theme,
              title: '치매상담전화 바로가기',
              description: '치매안심센터 콜센터(1899-9988)로 연결합니다.',
              icon: Icons.support_agent,
              onTap: () => _launchPhone(context, '18999988'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterCard(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String description,
    required String actionText,
    required IconData actionIcon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description,
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onTap,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionText,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(description,
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
