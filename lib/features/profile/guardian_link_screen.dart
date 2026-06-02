import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/user_provider.dart';
import '../../core/services/guardian_sync_service.dart';
import '../gait_analysis/pedometer_manager.dart';

class GuardianLinkScreen extends StatefulWidget {
  const GuardianLinkScreen({super.key});

  @override
  State<GuardianLinkScreen> createState() => _GuardianLinkScreenState();
}

class _GuardianLinkScreenState extends State<GuardianLinkScreen> {
  final _syncService = GuardianSyncService();

  String _dashboardUrl = '';
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  bool _isAnomaly = false;
  bool _hasSynced = false;

  @override
  void initState() {
    super.initState();
    _initToken();
  }

  Future<void> _initToken() async {
    final user = context.read<UserProvider>();
    final userId = user.currentUser?['id'] ?? 0;
    final token = await _syncService.getOrCreateToken(userId as int);
    if (mounted) {
      setState(() {
        _dashboardUrl = _syncService.guardianUrl(token);
      });
    }
  }

  Future<void> _syncNow() async {
    final user = context.read<UserProvider>();
    final pedometer = context.read<PedometerManager>();
    final userId = user.currentUser?['id'] ?? 0;
    final userName = user.currentUser?['username'] as String? ?? '어르신';

    setState(() => _isSyncing = true);

    final result = await _syncService.syncToFirestore(
      userId: userId as int,
      userName: userName,
      todaySteps: pedometer.todaySteps,
      emergencyContact: user.emergencyContact,
    );

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _hasSynced = true;
        if (result.success) {
          _lastSyncTime = DateTime.now();
          _isAnomaly = result.isAnomaly;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success ? '보호자 대시보드가 업데이트되었습니다.' : '동기화 실패: ${result.error}',
          ),
          backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
              'QR 코드를 스캔하면 앱 설치 없이\n어르신의 활동 상태를 실시간으로 확인할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            // 이상 감지 배너 (18시 이후 활동량 급감 시)
            if (_hasSynced && _isAnomaly)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade800.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.red.shade700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '활동량 이상 감지 — 보호자 대시보드에 경고가 표시됩니다.',
                        style: TextStyle(color: Colors.red.shade300, fontSize: 13),
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
                borderRadius: BorderRadius.circular(16),
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
                      Text(
                        _formatLastSync(),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _syncNow,
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
                          borderRadius: BorderRadius.circular(10),
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
                  borderRadius: BorderRadius.circular(24),
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
                        color: Colors.grey.shade600,
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

            const SizedBox(height: 28),

            // 보호자가 확인할 수 있는 항목
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  _InfoRow(icon: Icons.directions_walk, text: '오늘 걸음 수 및 주간 활동 추이'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.psychology, text: '인지 훈련 카테고리별 최신 점수'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.warning_amber, text: '활동량 이상 감지 시 경고 알림'),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.update, text: '마지막 동기화 시각'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 직접 연락 버튼
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
                        final userName =
                            user.currentUser?['username'] as String? ?? '어르신';
                        final message =
                            'MemoryLink 알림: $userName님이 건강 리포트를 공유했습니다.\n$_dashboardUrl';
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
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
