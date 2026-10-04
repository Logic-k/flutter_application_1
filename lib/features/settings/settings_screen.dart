import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/version_label.dart';
import '../../core/user_provider.dart';
import '../training/training_progress_provider.dart';
import '../../core/settings_provider.dart';
import '../../core/ml_widgets.dart';
import '../../core/motion/staggered_column.dart';
import '../../core/theme.dart';
import '../../core/app_config.dart';
import '../../core/ai/ai_key_service.dart';
import '../../core/ai/ai_chat_service.dart';
import '../../core/services/diary_notification_service.dart';
import '../../core/services/cloud_data_deletion_service.dart';
import '../profile/edit_profile_screen.dart';

/// 통합 설정 화면
///
/// 앱 전역 설정을 한 곳에 모은다:
///  - 화면/접근성 (글자 크기, 음성 안내, 진동)
///  - 알림 (매일 저녁 일기 알림)
///  - AI (Gemini API 키, 온디바이스 모델)
///  - 계정 (프로필 편집, 보호자 연결)
///  - 개인정보·데이터 (처리방침, 측정 데이터 초기화)
///  - 정보 (버전, 오픈소스 라이선스, 로그아웃)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 일기 알림은 기본 꺼짐이다. 켤 때 알림 권한을 묻는다(LAUNCH_AUDIT P0-04).
  bool _reminderEnabled = false;
  bool _hasApiKey = false;
  bool _loadingAi = true;
  String _providerName = '';

  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _showKeyEditor = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = await AiKeyService.getStoredKey();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = prefs.getBool(DiaryNotificationService.prefKey) ?? false;
      _hasApiKey = storedKey != null;
      _providerName = AiChatService.currentProviderName;
      _loadingAi = false;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  // ─── 알림 토글 ───────────────────────────────────────────────
  Future<void> _toggleReminder(bool enabled) async {
    String message;
    if (enabled) {
      final result = await DiaryNotificationService.enable();
      if (!mounted) return;
      setState(() => _reminderEnabled = result == DiaryReminderResult.enabled);
      message = switch (result) {
        DiaryReminderResult.enabled => '매일 저녁 7시 무렵 일기 알림을 보내 드립니다.',
        DiaryReminderResult.permissionDenied =>
          '알림 권한이 꺼져 있습니다. 휴대폰 설정에서 MemoryLink 알림을 허용한 뒤 다시 켜 주세요.',
        DiaryReminderResult.unavailable => '이 기기에서는 알림을 준비하지 못했습니다.',
      };
    } else {
      setState(() => _reminderEnabled = false);
      await DiaryNotificationService.disable();
      if (!mounted) return;
      message = '일기 알림이 꺼졌습니다.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Gemini API 키 ───────────────────────────────────────────
  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _loadingAi = true);
    await AiChatService.applyApiKey(key);
    _apiKeyController.clear();
    await _loadState();
    if (mounted) {
      setState(() => _showKeyEditor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API 키가 저장되었습니다.')),
      );
    }
  }

  Future<void> _removeApiKey() async {
    setState(() => _loadingAi = true);
    await AiChatService.removeApiKey();
    await _loadState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 키가 삭제되었습니다. 오프라인 모드로 전환됩니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        // 섹션 묶음이 60ms 간격으로 들어온다(08 계획 G-04, 첫 진입 1회).
        child: StaggeredColumn(
          playKey: 'settings',
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // ─── 화면 / 접근성 ───
            MLSectionTitle('화면 및 접근성'),
            MLCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _fontSizeRow(settings),
                const Divider(),
                MLListRow(
                  icon: Icons.record_voice_over_rounded, color: MLColors.mem,
                  title: '음성 안내',
                  subtitle: '핵심 정보와 안내를 읽어줍니다.',
                  trailing: Switch(
                    value: settings.voiceGuidanceEnabled,
                    onChanged: (v) => context.read<SettingsProvider>().setVoiceGuidance(v),
                  ),
                ),
                const Divider(),
                MLListRow(
                  icon: Icons.vibration_rounded, color: MLColors.logic,
                  title: '진동 피드백',
                  subtitle: '버튼 클릭 시 진동으로 반응합니다.',
                  trailing: Switch(
                    value: settings.hapticFeedbackEnabled,
                    onChanged: (v) => context.read<SettingsProvider>().setHapticFeedback(v),
                  ),
                ),
                const Divider(),
                MLListRow(
                  icon: Icons.music_note_rounded, color: MLColors.sky,
                  title: '효과음',
                  subtitle: '정답·오답·완료를 짧은 소리로 알립니다.',
                  trailing: Switch(
                    value: settings.soundEffectsEnabled,
                    onChanged: (v) => context.read<SettingsProvider>().setSoundEffects(v),
                  ),
                ),
                const Divider(),
                MLListRow(
                  icon: Icons.motion_photos_off_rounded, color: MLColors.mem,
                  title: '움직임 줄이기',
                  // 켜면 이동·확대 효과를 끄고 부드러운 흐려짐만 남긴다(MotionLevel.fadeOnly).
                  subtitle: '움직이는 효과를 끄고 부드러운 전환만 남깁니다.',
                  trailing: Switch(
                    value: settings.reduceMotion,
                    onChanged: (v) => context.read<SettingsProvider>().setReduceMotion(v),
                  ),
                ),
              ]),
            ),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 22),

            // ─── 알림 ───
            MLSectionTitle('알림'),
            MLCard(
              padding: EdgeInsets.zero,
              child: MLListRow(
                icon: Icons.notifications_active_rounded, color: MLColors.sky,
                title: '매일 저녁 일기 알림',
                subtitle: '저녁 7시 무렵 일기 작성을 알려드립니다.',
                trailing: Switch(
                  value: _reminderEnabled,
                  onChanged: _toggleReminder,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ─── AI ───
            MLSectionTitle('AI 대화'),
            _buildAiCard(),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 22),

            // ─── 계정 ───
            MLSectionTitle('계정'),
            MLCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                MLListRow(
                  icon: Icons.person_outline_rounded, color: context.scheme.primary,
                  title: '프로필 편집',
                  subtitle: '이름, 나이, 건강 정보 수정',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                const Divider(),
                MLListRow(
                  icon: Icons.family_restroom_rounded, color: MLColors.sky,
                  title: '보호자 안심 연결',
                  subtitle: '보호자가 활동 상태를 확인할 수 있습니다.',
                  onTap: () => context.push('/guardian_link'),
                ),
              ]),
            ),
            const SizedBox(height: 22),

            // ─── 개인정보 및 데이터 ───
            MLSectionTitle('개인정보 및 데이터'),
            MLCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                MLListRow(
                  icon: Icons.privacy_tip_outlined, color: MLColors.logic,
                  title: '개인정보 처리방침',
                  onTap: _openPrivacyPolicy,
                ),
                const Divider(),
                MLListRow(
                  icon: Icons.refresh_rounded, color: MLColors.warn, titleColor: MLColors.warnText,
                  title: '측정 데이터 초기화',
                  subtitle: '인지 점수 및 기록만 삭제됩니다. (계정 유지)',
                  onTap: () => _showResetDialog(userProvider),
                ),
                const Divider(),
                MLListRow(
                  icon: Icons.cloud_off_rounded, color: MLColors.bad, titleColor: MLColors.badText,
                  title: '서버에 저장된 내 데이터 삭제',
                  subtitle: '보호자 링크와 1:1 문의를 서버에서 지웁니다. (기기 기록 유지)',
                  onTap: () => _showCloudDeleteDialog(userProvider),
                ),
              ]),
            ),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 22),

            // ─── 정보 ───
            MLSectionTitle('정보'),
            MLCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                MLListRow(
                  icon: Icons.info_outline_rounded, color: context.scheme.onSurfaceVariant,
                  title: '앱 버전',
                  trailing: Text('v1.0.0', style: TextStyle(color: context.scheme.onSurfaceVariant)),
                ),
                const Divider(),
                MLListRow(
                  icon: Icons.description_outlined, color: context.scheme.onSurfaceVariant,
                  title: '오픈소스 라이선스',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'MemoryLink',
                    applicationVersion: 'v1.0.0',
                  ),
                ),
                const Divider(),
                MLListRow(
                  icon: Icons.logout_rounded, color: MLColors.bad, titleColor: MLColors.badText,
                  title: '로그아웃',
                  onTap: () => _confirmLogout(userProvider),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            const MLVersionLabel(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 글자 크기 (인라인 세그먼트) ─────────────────────────────
  Widget _fontSizeRow(SettingsProvider settings) {
    const labels = {
      AppFontSize.normal: '기본',
      AppFontSize.large: '크게',
      AppFontSize.extraLarge: '아주 크게',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.text_fields_rounded, color: MLColors.calc, size: 22),
            SizedBox(width: 12),
            Text('글자 크기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          SegmentedButton<AppFontSize>(
            segments: AppFontSize.values
                .map((s) => ButtonSegment(value: s, label: Text(labels[s]!)))
                .toList(),
            selected: {settings.fontSize},
            onSelectionChanged: (sel) =>
                context.read<SettingsProvider>().setFontSize(sel.first),
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }

  // ─── AI 카드 ─────────────────────────────────────────────────
  Widget _buildAiCard() {
    if (_loadingAi) {
      // AI 카드 모양(상태 행 + 설명 두 줄)의 자리(08 계획 G-05).
      return Semantics(
        label: 'AI 설정을 불러오는 중',
        excludeSemantics: true,
        child: const MLSkeletonCard(lines: 2),
      );
    }

    final usingOndevice = AiChatService.isUsingLocalModel;
    final usingAi = AiChatService.isUsingAI;
    final statusColor = usingAi ? MLColors.goodText : context.scheme.onSurfaceVariant;
    final statusLabel = usingOndevice
        ? '온디바이스 AI 사용 중'
        : (_hasApiKey ? 'Gemini API 사용 중' : '오프라인(규칙 기반) 모드');

    return MLCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        // 현재 상태
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            Icon(Icons.circle, size: 10, color: statusColor),
            const SizedBox(width: 8),
            Expanded(child: Text(statusLabel,
                style: TextStyle(fontWeight: FontWeight.w700, color: statusColor))),
            Text(_providerName, style: TextStyle(fontSize: 12, color: context.scheme.onSurfaceVariant)),
          ]),
        ),
        if (AppConfig.isGenerativeAiEnabled) ...[
        const Divider(),

        // Gemini API 키
        if (!usingOndevice) ...[
          MLListRow(
            icon: Icons.key_rounded, color: context.scheme.primary,
            title: 'Gemini API 키',
            subtitle: _hasApiKey ? '키가 저장되어 있습니다.' : '키를 입력하면 온라인 AI 대화를 사용합니다.',
            trailing: _hasApiKey
                ? TextButton(onPressed: _removeApiKey,
                    child: const Text('삭제', style: TextStyle(color: MLColors.badText)))
                : Icon(Icons.chevron_right_rounded, color: context.scheme.onSurfaceVariant),
            onTap: () => setState(() => _showKeyEditor = !_showKeyEditor),
          ),
          if (_showKeyEditor)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(children: [
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    hintText: 'AIza... 형식의 Gemini API 키',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, size: 20),
                      tooltip: _obscureKey ? 'API 키 표시' : 'API 키 숨기기',
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.rField)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://aistudio.google.com/app/apikey'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('키 발급받기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(onPressed: _saveApiKey, child: const Text('저장')),
                  ),
                ]),
                if (AppConfig.geminiApiKey.isNotEmpty && !_hasApiKey)
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('빌드에 기본 키가 주입되어 있어 키 없이도 온라인 AI가 동작할 수 있습니다.',
                        style: TextStyle(fontSize: 12, color: context.scheme.onSurfaceVariant)),
                  ),
              ]),
            ),
          const Divider(),
        ],

        // 온디바이스 모델
        MLListRow(
          icon: Icons.memory_rounded, color: MLColors.calc,
          title: '온디바이스 AI 모델',
          subtitle: usingOndevice ? '활성화됨 · 인터넷 없이 동작' : '인터넷 없이 동작하는 AI 모델 관리',
          onTap: () async {
            await context.push('/ondevice-ai');
            if (mounted) _loadState();
          },
        ),
        ],
      ]),
    );
  }

  // ─── 개인정보 처리방침 ───────────────────────────────────────
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(AppConfig.privacyPolicyUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('개인정보 처리방침 페이지를 열 수 없습니다.')),
      );
    }
  }

  void _showCloudDeleteDialog(UserProvider userProvider) {
    final user = userProvider.currentUser;
    if (user == null) return;
    var isDeleting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('서버 데이터 삭제'),
          content: const Text(
            '보호자 링크가 바로 끊기고, 보낸 1:1 문의와 답변이 서버에서 지워집니다. '
            '이 휴대폰 안의 계정과 건강 기록, 일기는 그대로 남습니다.',
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      final result = await CloudDataDeletionService().deleteFor(
                        userId: user['id'] as int,
                        username: (user['username'] as String?) ?? '',
                      );
                      if (!ctx.mounted || !mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.success
                              ? '서버에 저장된 데이터를 지웠습니다.'
                              : '${result.failed.join(', ')}을(를) 지우지 못했습니다. '
                                  '연결 상태를 확인하고 다시 시도해 주세요.'),
                        ),
                      );
                    },
              child: const Text('삭제', style: TextStyle(color: MLColors.badText)),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(UserProvider userProvider) {
    var isResetting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('데이터 초기화'),
          content: const Text(
            '인지 훈련 점수와 활동 기록, XP, 숙련도, 연속 학습 기록이 모두 삭제됩니다. '
            '계정은 유지되며 시작 활동은 다시 열립니다.',
          ),
          actions: [
            TextButton(
              onPressed: isResetting ? null : () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: isResetting
                  ? null
                  : () async {
                      setDialogState(() => isResetting = true);
                      try {
                        await userProvider.resetMeasurementData();
                        if (!ctx.mounted || !mounted) return;
                        await context
                            .read<TrainingProgressProvider>()
                            .refresh();
                        if (!ctx.mounted || !mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('데이터가 초기화되었습니다.'),
                          ),
                        );
                      } catch (_) {
                        if (!ctx.mounted || !mounted) return;
                        setDialogState(() => isResetting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '데이터를 초기화하지 못했습니다. 다시 시도해 주세요.',
                            ),
                          ),
                        );
                      }
                    },
              child: isResetting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '초기화',
                      style: TextStyle(color: MLColors.warnText),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              userProvider.logout();
              context.go('/login');
            },
            child: const Text('로그아웃', style: TextStyle(color: MLColors.badText)),
          ),
        ],
      ),
    );
  }
}
