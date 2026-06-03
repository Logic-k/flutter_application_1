import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/user_provider.dart';
import '../../core/settings_provider.dart';
import '../../core/ml_widgets.dart';
import '../../core/theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: MLColors.primary)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, user, userProvider),
            const SizedBox(height: 22),

            MLSectionTitle('건강 정보'),
            _buildHealthCard(userProvider, context),
            const SizedBox(height: 22),

            MLSectionTitle('가족 및 연결'),
            MLCard(
              padding: EdgeInsets.zero,
              child: MLListRow(
                icon: Icons.family_restroom_rounded, color: MLColors.sky,
                title: '보호자 안심 연결',
                subtitle: '보호자가 활동 상태를 확인할 수 있습니다.',
                onTap: () => context.push('/guardian_link'),
              ),
            ),
            const SizedBox(height: 22),

            MLSectionTitle('고객센터'),
            Semantics(
              identifier: 'cs_center_card',
              child: MLCard(
                padding: EdgeInsets.zero,
                child: MLListRow(
                  icon: Icons.support_agent_rounded, color: MLColors.primary,
                  title: '고객센터',
                  subtitle: '공지사항, FAQ, 1:1 문의',
                  onTap: () => context.push('/cs_center'),
                ),
              ),
            ),
            const SizedBox(height: 22),

            MLSectionTitle('앱 설정'),
            _buildSettingsCard(context),
            const SizedBox(height: 22),

            MLSectionTitle('데이터 관리'),
            _buildAccountCard(context, userProvider),
            const SizedBox(height: 32),

            Center(
              child: GestureDetector(
                onLongPress: () => context.push('/admin_login'),
                child: const Text('MemoryLink v1.0.0', style: TextStyle(fontSize: 12, color: MLColors.textFaint)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 헤더 (아바타 + 이름 + 편집 버튼) ────────────────────────
  Widget _buildHeader(BuildContext context, Map<String, dynamic> user, UserProvider userProvider) {
    return MLCard(
      child: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          final imagePath = snapshot.data?.getString('profile_image_path');
          final hasImage = imagePath != null && File(imagePath).existsSync();

          return Row(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: MLColors.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                  image: hasImage ? DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover) : null,
                ),
                child: hasImage ? null : const Icon(Icons.person_rounded, size: 36, color: MLColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['username'] ?? '사용자', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('ID: ${user['id']}', style: const TextStyle(fontSize: 13, color: MLColors.textSoft)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MLColors.primary,
                  side: const BorderSide(color: MLColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.rBtn)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('편집', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── 건강 정보 카드 ────────────────────────────────────────────
  Widget _buildHealthCard(UserProvider up, BuildContext context) {
    return MLCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        MLListRow(icon: Icons.calendar_today_rounded, color: MLColors.calc, title: '나이', trailing: Text('${up.age ?? "-"} 세', style: const TextStyle(fontWeight: FontWeight.w700))),
        Divider(height: 1, color: MLColors.line),
        MLListRow(icon: Icons.monitor_weight_rounded, color: MLColors.mem, title: '몸무게', trailing: Text('${up.weight ?? "-"} kg', style: const TextStyle(fontWeight: FontWeight.w700))),
        Divider(height: 1, color: MLColors.line),
        MLListRow(icon: Icons.bloodtype_rounded, color: MLColors.bad, title: '혈액형', trailing: Text(up.bloodType ?? '미설정', style: const TextStyle(fontWeight: FontWeight.w700))),
        Divider(height: 1, color: MLColors.line),
        MLListRow(icon: Icons.medical_services_rounded, color: MLColors.warn, title: '복용 약물', trailing: Text(up.medications ?? '없음', style: const TextStyle(fontWeight: FontWeight.w700))),
        Divider(height: 1, color: MLColors.line),
        MLListRow(icon: Icons.notifications_active_rounded, color: MLColors.sky, title: '비상 연락처', trailing: Text(up.emergencyContact ?? '미설정', style: const TextStyle(fontWeight: FontWeight.w700))),
        Divider(height: 1, color: MLColors.line),
        MLListRow(icon: Icons.mic_rounded, color: MLColors.logic, title: '음성 진단', subtitle: '인지 건강 초기 진단 재실행', onTap: () => context.push('/voice_assessment')),
      ]),
    );
  }

  // ─── 앱 설정 카드 ─────────────────────────────────────────────
  Widget _buildSettingsCard(BuildContext context) {
    return MLCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        MLListRow(
          icon: Icons.text_fields_rounded, color: MLColors.calc,
          title: '글자 크기 설정',
          onTap: () => _showFontSizeDialog(context),
        ),
        Divider(height: 1, color: MLColors.line),
        MLListRow(
          icon: Icons.record_voice_over_rounded, color: MLColors.mem,
          title: '음성 안내',
          subtitle: '핵심 정보와 안내 사항을 읽어줍니다.',
          trailing: Switch(
            value: context.watch<SettingsProvider>().voiceGuidanceEnabled,
            onChanged: (v) => context.read<SettingsProvider>().setVoiceGuidance(v),
            activeThumbColor: MLColors.primary,
          ),
        ),
        Divider(height: 1, color: MLColors.line),
        MLListRow(
          icon: Icons.vibration_rounded, color: MLColors.logic,
          title: '진동 피드백',
          subtitle: '버튼 클릭 시 진동으로 반응합니다.',
          trailing: Switch(
            value: context.watch<SettingsProvider>().hapticFeedbackEnabled,
            onChanged: (v) => context.read<SettingsProvider>().setHapticFeedback(v),
            activeThumbColor: MLColors.primary,
          ),
        ),
      ]),
    );
  }

  // ─── 데이터 관리 카드 ─────────────────────────────────────────
  Widget _buildAccountCard(BuildContext context, UserProvider userProvider) {
    return MLCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        MLListRow(
          icon: Icons.refresh_rounded, color: MLColors.warn, titleColor: MLColors.warn,
          title: '측정 데이터 초기화',
          subtitle: '인지 점수 및 기록만 삭제됩니다.',
          onTap: () => _showResetDialog(context, userProvider),
        ),
        Divider(height: 1, color: MLColors.line),
        MLListRow(
          icon: Icons.logout_rounded, color: MLColors.bad, titleColor: MLColors.bad,
          title: '로그아웃',
          onTap: () {
            userProvider.logout();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ]),
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
                    .map((size) => RadioListTile<AppFontSize>(title: Text(labels[size]!), value: size))
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 초기화'),
        content: const Text('지금까지의 인지 훈련 점수와 활동 기록이 모두 삭제됩니다. 정말 초기화하시겠습니까? (계정은 유지됩니다)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              userProvider.resetMeasurementData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('데이터가 초기화되었습니다.')));
            },
            child: const Text('초기화', style: TextStyle(color: MLColors.warn)),
          ),
        ],
      ),
    );
  }
}
