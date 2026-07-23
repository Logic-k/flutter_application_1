import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/user_provider.dart';
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
            onPressed: () => context.push('/settings'),
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
            MLCard(
              padding: EdgeInsets.zero,
              child: MLListRow(
                icon: Icons.settings_rounded, color: MLColors.calc,
                title: '설정',
                subtitle: '글자 크기, 알림, AI, 개인정보, 로그아웃',
                onTap: () => context.push('/settings'),
              ),
            ),
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
          // 사진 경로는 계정별로 저장한다 (계정 전환 시 이전 사용자 사진 노출 방지)
          final imagePath =
              snapshot.data?.getString('profile_image_path_${user['id']}');
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
                    Text(
                      (user['name'] as String?)?.isNotEmpty == true ? user['name'] : user['username'] ?? '사용자',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text('아이디: ${user['username'] ?? ''}', style: const TextStyle(fontSize: 13, color: MLColors.textSoft)),
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
        MLListRow(icon: Icons.mic_off_rounded, color: MLColors.textSoft, title: '음성 진단', subtitle: '정확도 개선을 위해 현재 사용 중지', onTap: () => context.push('/voice_assessment')),
        Divider(height: 1, color: MLColors.line),
        MLListRow(icon: Icons.health_and_safety_rounded, color: MLColors.primary, title: '건강 기록', subtitle: '수면·혈압·식이 기록 및 추세', onTap: () => context.push('/health_input')),
      ]),
    );
  }

}
