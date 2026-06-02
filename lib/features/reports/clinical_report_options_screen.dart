import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database_helper.dart';
import '../../core/user_provider.dart';
import 'clinical_report_generator.dart';
import 'models/clinical_report_data.dart';

class ClinicalReportOptionsScreen extends StatefulWidget {
  const ClinicalReportOptionsScreen({super.key});

  @override
  State<ClinicalReportOptionsScreen> createState() =>
      _ClinicalReportOptionsScreenState();
}

class _ClinicalReportOptionsScreenState
    extends State<ClinicalReportOptionsScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  ReportType? _selectedType;
  bool _caregiverPresent = false;
  RiskFactors _riskFactors = const RiskFactors();

  bool _isGenerating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _generateAndShare({bool preview = false}) async {
    if (_selectedType == null) return;
    setState(() => _isGenerating = true);

    try {
      final user = context.read<UserProvider>();
      final db = DatabaseHelper();

      final reportData = await ClinicalReportData.fromProviders(
        user: user,
        db: db,
        reportType: _selectedType!,
        riskFactors: _riskFactors,
        caregiverPresent: _caregiverPresent,
      );

      final file = await ClinicalReportGenerator.generate(reportData);

      if (!mounted) return;

      if (preview) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _PdfPreviewPage(file: file),
          ),
        );
      } else {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'MemoryLink 임상 리포트',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리포트 생성 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('임상 리포트 생성'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: Column(
        children: [
          _buildStepIndicator(theme),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepType(theme),
                _buildStepRiskFactors(theme),
                _buildStepCaregiver(theme),
                _buildStepConfirm(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(4, (i) {
          final active = i == _currentStep;
          final done = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? theme.colorScheme.primary
                        : active
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: done
                        ? Icon(Icons.check,
                            size: 16, color: theme.colorScheme.onPrimary)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: active
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Step 0: 리포트 유형 선택
  Widget _buildStepType(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('리포트 유형을 선택해주세요',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('상담 대상에 맞는 리포트를 선택하면\n더 적합한 내용이 포함됩니다.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          _buildTypeCard(
            theme,
            type: ReportType.doctor,
            icon: Icons.medical_services_outlined,
            title: '의료진용 리포트',
            subtitle: '점수·추이·임상 권고사항·전문의 의뢰 기준',
          ),
          const SizedBox(height: 16),
          _buildTypeCard(
            theme,
            type: ReportType.caregiver,
            icon: Icons.favorite_outline,
            title: '보호자용 리포트',
            subtitle: '일상 기능 변화·주의 행동·병원 방문 신호',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedType != null ? _nextStep : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('다음'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
    ThemeData theme, {
    required ReportType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // Step 1: 위험요인 체크리스트
  Widget _buildStepRiskFactors(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('건강 위험요인 확인',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('해당되는 항목을 체크해주세요. (선택사항)',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildRiskCheckbox(
                  theme,
                  label: '수면 문제',
                  desc: '잠들기 어렵거나 수면이 부족함',
                  icon: Icons.bedtime_outlined,
                  value: _riskFactors.poorSleep,
                  onChanged: (v) => setState(() =>
                      _riskFactors = _riskFactors.copyWith(poorSleep: v)),
                ),
                _buildRiskCheckbox(
                  theme,
                  label: '우울하거나 의욕 저하',
                  desc: '우울하거나 의욕이 없는 날이 많음',
                  icon: Icons.sentiment_dissatisfied_outlined,
                  value: _riskFactors.depressiveMood,
                  onChanged: (v) => setState(() =>
                      _riskFactors = _riskFactors.copyWith(depressiveMood: v)),
                ),
                _buildRiskCheckbox(
                  theme,
                  label: '청력 저하',
                  desc: '청력이 예전보다 나빠졌음',
                  icon: Icons.hearing_outlined,
                  value: _riskFactors.hearingDifficulty,
                  onChanged: (v) => setState(() => _riskFactors =
                      _riskFactors.copyWith(hearingDifficulty: v)),
                ),
                _buildRiskCheckbox(
                  theme,
                  label: '운동 부족',
                  desc: '운동을 거의 하지 않음',
                  icon: Icons.directions_walk,
                  value: _riskFactors.lowExercise,
                  onChanged: (v) => setState(() =>
                      _riskFactors = _riskFactors.copyWith(lowExercise: v)),
                ),
                _buildRiskCheckbox(
                  theme,
                  label: '사회적 고립',
                  desc: '사람들과 교류가 적고 혼자 있는 시간이 많음',
                  icon: Icons.people_outline,
                  value: _riskFactors.socialIsolation,
                  onChanged: (v) => setState(() => _riskFactors =
                      _riskFactors.copyWith(socialIsolation: v)),
                ),
                _buildRiskCheckbox(
                  theme,
                  label: '고혈압',
                  desc: '고혈압 진단을 받았거나 약을 복용 중',
                  icon: Icons.monitor_heart_outlined,
                  value: _riskFactors.hypertension,
                  onChanged: (v) => setState(() =>
                      _riskFactors = _riskFactors.copyWith(hypertension: v)),
                ),
                _buildRiskCheckbox(
                  theme,
                  label: '당뇨',
                  desc: '당뇨 진단을 받았거나 혈당 관리 중',
                  icon: Icons.water_drop_outlined,
                  value: _riskFactors.diabetes,
                  onChanged: (v) => setState(() =>
                      _riskFactors = _riskFactors.copyWith(diabetes: v)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _nextStep,
                  child: const Text('건너뛰기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _nextStep,
                  child: const Text('다음'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCheckbox(
    ThemeData theme, {
    required String label,
    required String desc,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 22, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  Text(desc,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: 보호자 동반 여부
  Widget _buildStepCaregiver(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('보호자와 함께 하셨나요?',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('리포트에 보호자 동반 여부가 기록됩니다.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 40),
          _buildCaregiverCard(
            theme,
            value: true,
            icon: Icons.group_outlined,
            title: '예, 보호자와 함께 했습니다',
          ),
          const SizedBox(height: 16),
          _buildCaregiverCard(
            theme,
            value: false,
            icon: Icons.person_outline,
            title: '혼자 했습니다',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextStep,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('다음'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverCard(ThemeData theme,
      {required bool value, required IconData icon, required String title}) {
    final selected = _caregiverPresent == value;
    return GestureDetector(
      onTap: () => setState(() => _caregiverPresent = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal)),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // Step 3: 확인 및 생성
  Widget _buildStepConfirm(ThemeData theme) {
    final typeLabel =
        _selectedType == ReportType.doctor ? '의료진용' : '보호자용';
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('리포트 생성 준비 완료',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('아래 내용으로 PDF를 생성합니다.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          _buildSummaryRow(theme, '리포트 유형', typeLabel,
              Icons.description_outlined),
          _buildSummaryRow(theme, '위험요인',
              '${_riskFactors.checkedCount}개 선택됨', Icons.warning_amber_outlined),
          _buildSummaryRow(theme, '보호자 동반',
              _caregiverPresent ? '예' : '아니오', Icons.group_outlined),
          _buildSummaryRow(theme, '생성 날짜', dateStr, Icons.calendar_today),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이 결과는 선별 목적이며 의학적 진단을 대체하지 않습니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_isGenerating)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('리포트 생성 중...'),
                ],
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _generateAndShare(preview: false),
                    icon: const Icon(Icons.share),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('PDF 생성 및 공유하기'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _generateAndShare(preview: true),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('미리보기'),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      ThemeData theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label:',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PdfPreviewPage extends StatelessWidget {
  final File file;
  const _PdfPreviewPage({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리포트 미리보기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Share.shareXFiles([XFile(file.path)],
                  text: 'MemoryLink 임상 리포트');
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => file.readAsBytesSync(),
        allowPrinting: true,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
