import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CsCenterScreen extends StatelessWidget {
  const CsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('고객센터')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMenuCard(
            context,
            icon: Icons.campaign_outlined,
            title: '공지사항',
            subtitle: '서비스 업데이트 및 안내',
            route: '/cs/notices',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.quiz_outlined,
            title: '자주 묻는 질문',
            subtitle: '이용 중 궁금한 점 확인',
            route: '/cs/faq',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.mail_outline,
            title: '1:1 문의하기',
            subtitle: '직접 문의 접수',
            route: '/cs/inquiry_submit',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.inbox_outlined,
            title: '내 문의 내역',
            subtitle: '접수한 문의 및 답변 확인',
            route: '/cs/my_inquiries',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required ThemeData theme,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}
