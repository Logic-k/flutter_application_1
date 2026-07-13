import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/user_provider.dart';
import '../../core/settings_provider.dart';
import '../../core/ml_widgets.dart';
import '../../core/theme.dart';
import '../../core/app_config.dart';
import '../../core/ai/ai_key_service.dart';
import '../../core/ai/ai_chat_service.dart';
import '../../core/services/diary_notification_service.dart';
import '../../main.dart' show flutterLocalNotificationsPlugin;
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
  static const _reminderPrefKey = 'diary_reminder_enabled';

  bool _reminderEnabled = true;
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
      _reminderEnabled = prefs.getBool(_reminderPrefKey) ?? true;
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
    setState(() => _reminderEnabled = enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderPrefKey, enabled);
    if (enabled) {
      await DiaryNotificationService.scheduleDailyReminder(
          flutterLocalNotificationsPlugin);
    } else {
      await DiaryNotificationService.cancelReminder(
          flutterLocalNotificationsPlugin);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enabled ? '매일 저녁 7시 일기 알림이 켜졌습니다.' : '일기 알림이 꺼졌습니다.')),
      );
    }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 화면 / 접근성 ───
            MLSectionTitle('화면 및 접근성'),
            MLCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _fontSizeRow(settings),
                Divider(height: 1, color: MLColors.line),
                MLListRow(
                  icon: Icons.record_voice_over_rounded, color: MLColors.mem,
                  title: '음성 안내',
                  subtitle: '핵심 정보와 안내를 읽어줍니다.',
                  trailing: Switch(
                    value: settings.voiceGuidanceEnabled,
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
                    value: settings.hapticFeedbackEnabled,
                    onChanged: (v) => context.read<SettingsProvider>().setHapticFeedback(v),
                    activeThumbColor: MLColors.primary,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 22),

            // ─── 알림 ───
            MLSectionTitle('알림'),
            MLCard(
              padding: EdgeInsets.zero,
              child: MLListRow(
                icon: Icons.notifications_active_rounded, color: MLColors.sky,
                title: '매일 저녁 일기 알림',
                subtitle: '저녁 7시에 일기 작성을 알려드립니다.',
                trailing: Switch(
                  value: _reminderEnabled,
                  onChanged: _toggleReminder,
                  activeThumbColor: MLColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ─── AI ───
            MLSectionTitle('AI 대화'),
            _buildAiCard(),
            const SizedBox(height: 22),

            // ─── 계정 ───
            MLSectionTitle('계정'),
            MLCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                MLListRow(
                  icon: Icons.person_outline_rounded, color: MLColors.primary,
                  title: '프로필 편집',
                  subtitle: '이름, 나이, 건강 정보 수정',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                Divider(height: 1, color: MLColors.line),
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
                Divider(height: 1, color: MLColors.line),
                MLListRow(
                  icon: Icons.refresh_rounded, color: MLColors.warn, titleColor: MLColors.warn,
                  title: '측정 데이터 초기화',
                  subtitle: '인지 점수 및 기록만 삭제됩니다. (계정 유지)',
                  onTap: () => _showResetDialog(userProvider),
                ),
              ]),
            ),
            const SizedBox(height: 22),

            // ─── 정보 ───
            MLSectionTitle('정보'),
            MLCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                MLListRow(
                  icon: Icons.info_outline_rounded, color: MLColors.textSoft,
                  title: '앱 버전',
                  trailing: const Text('v1.0.0', style: TextStyle(color: MLColors.textSoft)),
                ),
                Divider(height: 1, color: MLColors.line),
                MLListRow(
                  icon: Icons.description_outlined, color: MLColors.textSoft,
                  title: '오픈소스 라이선스',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'MemoryLink',
                    applicationVersion: 'v1.0.0',
                  ),
                ),
                Divider(height: 1, color: MLColors.line),
                MLListRow(
                  icon: Icons.logout_rounded, color: MLColors.bad, titleColor: MLColors.bad,
                  title: '로그아웃',
                  onTap: () => _confirmLogout(userProvider),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            Center(
              child: GestureDetector(
                onLongPress: () => context.push('/admin_login'),
                child: const Text('MemoryLink v1.0.0',
                    style: TextStyle(fontSize: 12, color: MLColors.textFaint)),
              ),
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
      return const MLCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(color: MLColors.primary),
          ),
        ),
      );
    }

    final usingOndevice = AiChatService.isUsingLocalModel;
    final usingAi = AiChatService.isUsingAI;
    final statusColor = usingAi ? Colors.green : MLColors.textSoft;
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
            Text(_providerName, style: const TextStyle(fontSize: 11, color: MLColors.textFaint)),
          ]),
        ),
        const Divider(height: 1, color: MLColors.line),

        // Gemini API 키
        if (!usingOndevice) ...[
          MLListRow(
            icon: Icons.key_rounded, color: MLColors.primary,
            title: 'Gemini API 키',
            subtitle: _hasApiKey ? '키가 저장되어 있습니다.' : '키를 입력하면 온라인 AI 대화를 사용합니다.',
            trailing: _hasApiKey
                ? TextButton(onPressed: _removeApiKey,
                    child: const Text('삭제', style: TextStyle(color: MLColors.bad)))
                : const Icon(Icons.chevron_right_rounded, color: MLColors.textFaint),
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
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('빌드에 기본 키가 주입되어 있어 키 없이도 온라인 AI가 동작할 수 있습니다.',
                        style: TextStyle(fontSize: 11, color: MLColors.textFaint)),
                  ),
              ]),
            ),
          const Divider(height: 1, color: MLColors.line),
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

  void _showResetDialog(UserProvider userProvider) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('데이터가 초기화되었습니다.')),
              );
            },
            child: const Text('초기화', style: TextStyle(color: MLColors.warn)),
          ),
        ],
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
            child: const Text('로그아웃', style: TextStyle(color: MLColors.bad)),
          ),
        ],
      ),
    );
  }
}
