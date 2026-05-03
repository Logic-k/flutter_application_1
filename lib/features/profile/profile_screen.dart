import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/user_provider.dart';
import '../../core/settings_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('내 정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            _buildHeader(user, theme),
            const SizedBox(height: 24),

            // Medical Information Card
            _buildSectionTitle(theme, '건강 정보'),
            const SizedBox(height: 12),
            _buildMedicalCard(userProvider, theme),
            const SizedBox(height: 24),

            // Family & Link
            _buildSectionTitle(theme, '가족 및 연결'),
            const SizedBox(height: 12),
            _buildFamilyCard(context, theme),
            const SizedBox(height: 24),

            // CS Center
            _buildSectionTitle(theme, '고객센터'),
            const SizedBox(height: 12),
            _buildCsCard(context, theme),
            const SizedBox(height: 24),

            // App Settings
            _buildSectionTitle(theme, '앱 설정'),
            const SizedBox(height: 12),
            _buildSettingsList(context, theme),
            const SizedBox(height: 24),

            // Account Management
            _buildSectionTitle(theme, '데이터 관리'),
            const SizedBox(height: 12),
            _buildAccountActions(context, userProvider, theme),
            const SizedBox(height: 40),
            
            // App Version (길게 탭 → 관리자 포털)
            Center(
              child: GestureDetector(
                onLongPress: () => context.push('/admin_login'),
                child: Text(
                  'MemoryLink v1.0.0',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> user, ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['username'] ?? '사용자',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${user['id']}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMedicalCard(UserProvider userProvider, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.calendar_today, '나이', '${userProvider.age ?? "-"} 세'),
            const Divider(height: 24),
            _buildInfoRow(Icons.monitor_weight_outlined, '몸무게', '${userProvider.weight ?? "-"} kg'),
            const Divider(height: 24),
            _buildInfoRow(Icons.bloodtype_outlined, '혈액형', userProvider.bloodType ?? '미설정'),
            const Divider(height: 24),
            _buildInfoRow(Icons.medical_services_outlined, '복용 약물', userProvider.medications ?? '없음'),
            const Divider(height: 24),
            _buildInfoRow(Icons.notifications_active_outlined, '비상 연락처', userProvider.emergencyContact ?? '미설정'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Builder(builder: (context) {
      final t = Theme.of(context);
      return Row(
        children: [
          Icon(icon, size: 20, color: t.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 16, color: t.colorScheme.onSurface)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface),
          ),
        ],
      );
    });
  }

  Widget _buildSettingsList(BuildContext context, ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.text_fields_outlined),
            title: const Text('글자 크기 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFontSizeDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('테마 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('시스템 설정에서 테마를 변경할 수 있습니다.')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final uri = Uri.parse('app-settings:');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('설정 앱에서 알림 권한을 변경해주세요.')),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over_outlined),
            title: const Text('음성 안내'),
            subtitle: const Text('핵심 정보와 안내 사항을 읽어줍니다.'),
            value: context.watch<SettingsProvider>().voiceGuidanceEnabled,
            onChanged: (value) => context.read<SettingsProvider>().setVoiceGuidance(value),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('진동 피드백'),
            subtitle: const Text('버튼 클릭 시 진동으로 반응합니다.'),
            value: context.watch<SettingsProvider>().hapticFeedbackEnabled,
            onChanged: (value) => context.read<SettingsProvider>().setHapticFeedback(value),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    const labels = {
      AppFontSize.normal: '기본 (Normal)',
      AppFontSize.large: '조금 크게 (Large)',
      AppFontSize.extraLarge: '매우 크게 (Extra Large)',
    };
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('글자 크기 선택'),
            content: RadioGroup<AppFontSize>(
              groupValue: settings.fontSize,
              onChanged: (value) {
                if (value != null) {
                  settings.setFontSize(value);
                  setDialogState(() {});
                  Navigator.pop(dialogContext);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppFontSize.values
                    .map((size) => RadioListTile<AppFontSize>(
                          title: Text(labels[size]!),
                          value: size,
                        ))
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, UserProvider userProvider, ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('측정 데이터 초기화', style: TextStyle(color: Colors.orange)),
            subtitle: const Text('인지 점수 및 기록만 삭제됩니다.'),
            onTap: () => _showResetDialog(context, userProvider),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            onTap: () {
              userProvider.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 초기화'),
        content: const Text('지금까지의 인지 훈련 점수와 활동 기록이 모두 삭제됩니다. 정말 초기화하시겠습니까? (계정은 유지됩니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              userProvider.resetMeasurementData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('데이터가 초기화되었습니다.')),
              );
            },
            child: const Text('초기화', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCard(BuildContext context, ThemeData theme) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.family_restroom, color: Colors.blue),
        title: const Text('보호자 안심 연결'),
        subtitle: const Text('보호자가 활동 상태를 확인할 수 있습니다.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/guardian_link'),
      ),
    );
  }

  Widget _buildCsCard(BuildContext context, ThemeData theme) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.support_agent,
            color: theme.colorScheme.primary),
        title: const Text('고객센터'),
        subtitle: const Text('공지사항, FAQ, 1:1 문의'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/cs_center'),
      ),
    );
  }
}
