import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/user_provider.dart';
import '../../core/services/guardian_sync_service.dart';
import '../gait_analysis/pedometer_manager.dart';

class GuardianLinkScreen extends StatefulWidget {
  const GuardianLinkScreen({super.key, this.syncService});
  final GuardianSyncService? syncService;

  @override
  State<GuardianLinkScreen> createState() => _GuardianLinkScreenState();
}

class _GuardianLinkScreenState extends State<GuardianLinkScreen> {
  late final GuardianSyncService _syncService;

  String _dashboardUrl = '';
  bool _isSyncing = false;
  bool _isUpdatingLink = false;
  bool _stopped = false;
  DateTime? _lastSyncTime;
  bool _isAnomaly = false;
  bool _hasSynced = false;

  @override
  void initState() {
    super.initState();
    _syncService = widget.syncService ?? GuardianSyncService();
    _initToken();
  }

  int get _userId => (context.read<UserProvider>().currentUser?['id'] ?? 0) as int;

  /// 보호자 공개 사본에 보낼 호칭. 로그인 아이디는 보내지 않는다.
  String get _publicName =>
      (context.read<UserProvider>().currentUser?['name'] as String?)?.trim() ?? '';

  Future<void> _initToken() async {
    final userId = _userId;
    final stopped = await _syncService.isSharingStopped(userId);
    final token = stopped ? null : await _syncService.getOrCreateToken(userId);
    if (mounted) {
      setState(() {
        _stopped = stopped;
        _dashboardUrl = token == null ? '' : _syncService.guardianUrl(token);
      });
    }
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? MLColors.badText : MLColors.goodText,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _syncNow() async {
    if (_isSyncing || _stopped) return;
    final pedometer = context.read<PedometerManager>();
    final userId = _userId;
    final displayName = _publicName;

    setState(() => _isSyncing = true);

    GuardianSyncResult result;
    try {
      result = await _syncService.syncToFirestore(
        userId: userId,
        displayName: displayName,
        todaySteps: pedometer.todaySteps,
      );
    } catch (_) {
      result = const GuardianSyncResult(success: false, token: '', isAnomaly: false);
    }

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _hasSynced = result.success;
        if (result.success) {
          _lastSyncTime = DateTime.now();
          _isAnomaly = result.isAnomaly;
          if (result.token.isNotEmpty) _dashboardUrl = _syncService.guardianUrl(result.token);
        }
      });

      if (!result.success) {
        _showMessage('동기화하지 못했습니다. 연결 상태를 확인하고 다시 시도해 주세요.', error: true);
      } else if (result.rotated) {
        _showMessage('보호자 링크가 새로 만들어졌습니다. 보호자에게 새 QR이나 링크를 보내 주세요.');
      } else {
        _showMessage('보호자 화면이 업데이트되었습니다.');
      }
    }
  }

  Future<bool> _confirm({required String title, required String body, required String action}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _stopSharing() async {
    if (_isUpdatingLink) return;
    final ok = await _confirm(
      title: '보호자 공유를 중지할까요?',
      body: '지금 링크와 QR로는 더 이상 볼 수 없습니다. 다시 공유하면 새 링크가 만들어집니다.',
      action: '공유 중지',
    );
    if (!ok || !mounted) return;
    setState(() => _isUpdatingLink = true);
    final done = await _syncService.stopSharing(_userId);
    if (!mounted) return;
    setState(() {
      _isUpdatingLink = false;
      if (done) {
        _stopped = true;
        _dashboardUrl = '';
        _hasSynced = false;
        _isAnomaly = false;
        _lastSyncTime = null;
      }
    });
    if (done) {
      _showMessage('보호자 공유를 중지했습니다.');
    } else {
      _showMessage('공유를 중지하지 못했습니다. 연결 상태를 확인하고 다시 시도해 주세요.', error: true);
    }
  }

  Future<void> _reissue() async {
    if (_isUpdatingLink) return;
    final ok = await _confirm(
      title: '새 링크를 만들까요?',
      body: '예전 링크와 QR은 바로 끊깁니다. 보호자에게 새 QR이나 링크를 다시 보내 주세요.',
      action: '새 링크 만들기',
    );
    if (!ok || !mounted) return;
    setState(() => _isUpdatingLink = true);
    final token = await _syncService.reissue(_userId);
    if (!mounted) return;
    setState(() {
      _isUpdatingLink = false;
      if (token != null) {
        _stopped = false;
        _dashboardUrl = _syncService.guardianUrl(token);
        _hasSynced = false;
        _isAnomaly = false;
        _lastSyncTime = null;
      }
    });
    if (token == null) {
      _showMessage('새 링크를 만들지 못했습니다. 연결 상태를 확인하고 다시 시도해 주세요.', error: true);
    } else {
      _showMessage('새 링크를 만들었습니다. 지금 동기화를 누르면 보호자 화면이 열립니다.');
    }
  }

  Future<void> _resumeSharing() async {
    if (_isUpdatingLink) return;
    setState(() => _isUpdatingLink = true);
    final token = await _syncService.resumeSharing(_userId);
    if (!mounted) return;
    setState(() {
      _isUpdatingLink = false;
      _stopped = false;
      _dashboardUrl = _syncService.guardianUrl(token);
    });
  }

  String _formatLastSync() {
    if (_lastSyncTime == null) return '아직 동기화하지 않았습니다';
    final diff = DateTime.now().difference(_lastSyncTime!);
    if (diff.inMinutes < 1) return '방금 전 동기화';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전 동기화';
    return '${DateFormat('MM/dd HH:mm').format(_lastSyncTime!)} 동기화';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('보호자 안심 연결'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.security, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              '보호자님께 안심을 선물하세요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'QR 코드를 스캔하면 앱 설치 없이\n어르신이 동기화한 활동 요약을 볼 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            if (_stopped)
              _StoppedCard(busy: _isUpdatingLink, onResume: _resumeSharing)
            else ...[
              // 이상 감지 배너 (18시 이후 활동량 급감 시)
              if (_hasSynced && _isAnomaly)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: MLColors.bad.withValues(alpha: 0.15),
                    border: Border.all(color: MLColors.badText),
                    borderRadius: BorderRadius.circular(AppTheme.rField),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: MLColors.badText, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '활동량 이상 감지 — 보호자 화면에 경고가 표시됩니다.',
                          style: TextStyle(color: MLColors.badText, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // 동기화 상태 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.rTile),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasSynced ? Icons.cloud_done : Icons.cloud_off,
                          size: 18,
                          color: _hasSynced
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatLastSync(),
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSyncing || _isUpdatingLink ? null : _syncNow,
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync, size: 18),
                        label: Text(_isSyncing ? '동기화 중...' : '지금 동기화'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.rField),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // QR 코드
              if (_dashboardUrl.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.rSheet),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                            alpha: theme.brightness == Brightness.light ? 0.1 : 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _dashboardUrl,
                        version: QrVersions.auto,
                        size: 200.0,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '보호자 스마트폰으로 스캔',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(
                  height: 248,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],

            const SizedBox(height: 28),

            // 보호자가 확인할 수 있는 항목
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.rTile),
              ),
              child: const Column(
                children: [
                  _InfoRow(icon: Icons.badge_outlined, text: '내 이름(전화번호·아이디는 보내지 않음)'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.directions_walk, text: '오늘 걸음 수 및 주간 활동 추이'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.psychology, text: '인지 훈련 카테고리별 최신 점수'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.warning_amber, text: '활동량 이상 감지 시 경고 표시'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.update, text: '마지막 소식 시각(걸음 측정이 켜져 있으면 1시간마다 갱신)'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.lock_clock, text: '30일 동안 소식이 없으면 링크가 저절로 닫힘'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 직접 연락 버튼 (어르신 휴대폰에서 보호자에게)
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
                    onPressed: _dashboardUrl.isEmpty
                        ? null
                        : () async {
                            final phone = user.emergencyContact ?? '';
                            if (phone.isNotEmpty) {
                              final message =
                                  'MemoryLink 알림: ${user.displayName}님이 건강 리포트를 공유했습니다.\n$_dashboardUrl';
                              final url = Uri.parse(
                                  'sms:$phone?body=${Uri.encodeComponent(message)}');
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

            const SizedBox(height: 16),

            // 링크 공유 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _dashboardUrl.isEmpty
                    ? null
                    : () {
                        Share.share(
                          '어르신의 건강 상태를 확인할 수 있는 안심 링크입니다.\n$_dashboardUrl',
                          subject: 'MemoryLink 보호자 안심 연결',
                        );
                      },
                icon: const Icon(Icons.share),
                label: const Text('링크 공유하기 (카톡 등)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.rField),
                  ),
                ),
              ),
            ),

            // 링크 관리: 공유 중일 때만
            if (!_stopped && _dashboardUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUpdatingLink || _isSyncing ? null : _reissue,
                  icon: const Icon(Icons.autorenew),
                  label: const Text('새 링크 만들기'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUpdatingLink || _isSyncing ? null : _stopSharing,
                  icon: const Icon(Icons.link_off),
                  label: const Text('공유 중지'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MLColors.badText,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StoppedCard extends StatelessWidget {
  const _StoppedCard({required this.busy, required this.onResume});

  final bool busy;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.rTile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_off, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '보호자 공유가 중지되어 있습니다',
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '예전 링크로는 볼 수 없습니다. 다시 공유하면 새 QR이 만들어집니다.',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onResume,
              icon: const Icon(Icons.link),
              label: const Text('다시 공유하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.rField),
                ),
              ),
            ),
          ),
        ],
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
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
