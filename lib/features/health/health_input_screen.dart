import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/database_helper.dart';
import '../../core/user_provider.dart';
import '../../core/ml_widgets.dart';
import '../../core/theme.dart';

/// FINGER 건강 기록 화면
///
/// FINGER(다요인 치매 예방)의 혈관 위험 관리·수면·식이 요소를 이용자가 직접
/// 기록한다. 하루 1건(upsert) 기준으로 저장하고, 최근 추세를 함께 보여준다.
class HealthInputScreen extends StatefulWidget {
  const HealthInputScreen({super.key});

  @override
  State<HealthInputScreen> createState() => _HealthInputScreenState();
}

class _HealthInputScreenState extends State<HealthInputScreen> {
  final _db = DatabaseHelper();

  // FINGER 식이 항목(지중해식 지향) — 오늘 섭취한 항목 수 = diet_score(0~5)
  static const _dietItems = ['채소', '과일', '생선', '통곡물', '견과류'];

  double _sleepHours = 7;
  int _sleepQuality = 3; // 1~5
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final Set<int> _dietChecked = {};

  bool _loading = true;
  List<Map<String, dynamic>> _recent = [];

  String get _today => DateTime.now().toIso8601String().split('T')[0];
  int? get _userId =>
      context.read<UserProvider>().currentUser?['id'] as int?;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _glucoseCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _userId;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    Map<String, dynamic>? today;
    List<Map<String, dynamic>> recent = const [];
    try {
      today = await _db.getHealthLog(uid, _today);
      recent = await _db.getRecentHealthLogs(uid, 14);
    } catch (_) {
      // DB 접근 실패 시에도 빈 폼을 보여준다(무한 로딩 방지)
    }
    if (!mounted) return;
    setState(() {
      if (today != null) {
        _sleepHours = (today['sleep_hours'] as num?)?.toDouble() ?? 7;
        _sleepQuality = (today['sleep_quality'] as int?) ?? 3;
        if (today['systolic'] != null) _systolicCtrl.text = '${today['systolic']}';
        if (today['diastolic'] != null) _diastolicCtrl.text = '${today['diastolic']}';
        if (today['glucose'] != null) _glucoseCtrl.text = '${today['glucose']}';
        _memoCtrl.text = (today['memo'] as String?) ?? '';
        final ds = today['diet_score'] as int? ?? 0;
        _dietChecked
          ..clear()
          ..addAll(List.generate(ds, (i) => i));
      }
      _recent = recent;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    FocusScope.of(context).unfocus();
    await _db.upsertHealthLog(
      userId: uid,
      date: _today,
      sleepHours: _sleepHours,
      sleepQuality: _sleepQuality,
      systolic: int.tryParse(_systolicCtrl.text.trim()),
      diastolic: int.tryParse(_diastolicCtrl.text.trim()),
      glucose: double.tryParse(_glucoseCtrl.text.trim()),
      dietScore: _dietChecked.length,
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘의 건강 기록이 저장되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('건강 기록')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MLColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _IntroBanner(),
                  const SizedBox(height: 20),

                  MLSectionTitle('수면'),
                  _sleepCard(),
                  const SizedBox(height: 20),

                  MLSectionTitle('혈압 · 혈당'),
                  _vitalsCard(),
                  const SizedBox(height: 20),

                  MLSectionTitle('식이 (지중해식)'),
                  _dietCard(),
                  const SizedBox(height: 20),

                  MLSectionTitle('메모'),
                  MLCard(
                    child: TextField(
                      controller: _memoCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: '특이사항이 있으면 적어주세요 (선택)',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('오늘 기록 저장',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  MLSectionTitle('최근 추세'),
                  _trendCard(),
                ],
              ),
            ),
    );
  }

  // ─── 수면 카드 ───────────────────────────────────────────────
  Widget _sleepCard() {
    return MLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bedtime_rounded, color: MLColors.mem, size: 20),
            const SizedBox(width: 8),
            const Text('수면 시간', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${_sleepHours.toStringAsFixed(1)}시간',
                style: const TextStyle(fontWeight: FontWeight.w800, color: MLColors.primary)),
          ]),
          Slider(
            value: _sleepHours,
            min: 0, max: 12, divisions: 24,
            label: '${_sleepHours.toStringAsFixed(1)}h',
            activeColor: MLColors.primary,
            onChanged: (v) => setState(() => _sleepHours = v),
          ),
          const SizedBox(height: 4),
          const Text('수면의 질', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final level = i + 1;
              final selected = _sleepQuality == level;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _sleepQuality = level),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? MLColors.primary : MLColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$level',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : MLColors.primary,
                        )),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          const Text('1: 매우 나쁨 · 5: 매우 좋음',
              style: TextStyle(fontSize: 12, color: MLColors.textFaint)),
        ],
      ),
    );
  }

  // ─── 혈압/혈당 카드 ──────────────────────────────────────────
  Widget _vitalsCard() {
    return MLCard(
      child: Column(children: [
        Row(children: [
          Expanded(child: _numField(_systolicCtrl, '수축기(최고)', 'mmHg')),
          const SizedBox(width: 12),
          Expanded(child: _numField(_diastolicCtrl, '이완기(최저)', 'mmHg')),
        ]),
        const SizedBox(height: 12),
        _numField(_glucoseCtrl, '공복 혈당 (선택)', 'mg/dL'),
      ]),
    );
  }

  Widget _numField(TextEditingController ctrl, String label, String unit) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── 식이 카드 ───────────────────────────────────────────────
  Widget _dietCard() {
    return MLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('오늘 드신 항목을 선택하세요',
              style: TextStyle(fontSize: 13, color: MLColors.textSoft)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(_dietItems.length, (i) {
              final selected = _dietChecked.contains(i);
              return FilterChip(
                label: Text(_dietItems[i]),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _dietChecked.add(i);
                  } else {
                    _dietChecked.remove(i);
                  }
                }),
                selectedColor: MLColors.primarySoft,
                checkmarkColor: MLColors.primary,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text('식이 점수: ${_dietChecked.length} / 5',
              style: const TextStyle(fontWeight: FontWeight.w700, color: MLColors.primary)),
        ],
      ),
    );
  }

  // ─── 추세 카드 ───────────────────────────────────────────────
  Widget _trendCard() {
    final withSleep = _recent
        .where((r) => r['sleep_hours'] != null)
        .toList();
    if (withSleep.length < 2) {
      return MLCard(
        child: Row(children: const [
          Icon(Icons.insights_rounded, color: MLColors.textFaint),
          SizedBox(width: 10),
          Expanded(child: Text('기록이 2일 이상 쌓이면 수면 추세 그래프가 표시됩니다.',
              style: TextStyle(color: MLColors.textSoft))),
        ]),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < withSleep.length; i++) {
      spots.add(FlSpot(i.toDouble(), (withSleep[i]['sleep_hours'] as num).toDouble()));
    }
    final avgSleep = withSleep
            .map((r) => (r['sleep_hours'] as num).toDouble())
            .reduce((a, b) => a + b) /
        withSleep.length;

    final latestBp = _recent.reversed.firstWhere(
      (r) => r['systolic'] != null && r['diastolic'] != null,
      orElse: () => const {},
    );

    return MLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('수면 시간 추세', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('평균 ${avgSleep.toStringAsFixed(1)}시간',
                style: const TextStyle(fontSize: 12, color: MLColors.textFaint)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(LineChartData(
              minY: 0, maxY: 12,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: MLColors.primary,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        MLColors.primary.withValues(alpha: 0.28),
                        MLColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            )),
          ),
          if (latestBp.isNotEmpty) ...[
            const Divider(height: 24),
            Row(children: [
              const Icon(Icons.favorite_rounded, color: MLColors.bad, size: 18),
              const SizedBox(width: 8),
              Text('최근 혈압  ${latestBp['systolic']} / ${latestBp['diastolic']} mmHg',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MLColors.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.rCard),
      ),
      child: Row(children: const [
        Icon(Icons.health_and_safety_rounded, color: MLColors.primary),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            '수면·혈압·식이는 인지 건강과 밀접합니다.\n매일 기록하면 추세를 확인할 수 있어요.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ]),
    );
  }
}
