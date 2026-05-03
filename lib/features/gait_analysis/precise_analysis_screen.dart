import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'gait_provider.dart';

class PreciseGaitAnalysisScreen extends StatefulWidget {
  const PreciseGaitAnalysisScreen({super.key});

  @override
  State<PreciseGaitAnalysisScreen> createState() => _PreciseGaitAnalysisScreenState();
}

class _PreciseGaitAnalysisScreenState extends State<PreciseGaitAnalysisScreen> {
  Timer? _timer;
  int _secondsRemaining = 180; // 3분
  bool _isFinished = false;
  bool _isDualTask = false;
  String? _currentTask;
  final List<String> _tasks = [
    '100에서 7씩 거꾸로 빼기',
    '기억나는 동물 5가지 이상 말하기',
    '좋아하는 노래 제목 3가지 생각하기',
    '어제 드신 점심 메뉴 떠올리기',
    '좌우를 번갈아 보며 걷기',
  ];

  void _startAnalysis() {
    context.read<GaitProvider>().startMeasurement();
    _secondsRemaining = 180;
    _isFinished = false;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          // 40초마다 새로운 이중 과제 제시
          if (_isDualTask && _secondsRemaining % 40 == 0 && _secondsRemaining > 0) {
            _currentTask = (_tasks..shuffle()).first;
          } else if (_secondsRemaining % 40 == 30) {
            _currentTask = null; // 10초 후 과제 숨김
          }
        });
      } else {
        _stopAnalysis();
      }
    });
  }

  void _stopAnalysis() {
    _timer?.cancel();
    context.read<GaitProvider>().stopMeasurement();
    setState(() => _isFinished = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gaitProvider = context.watch<GaitProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('정밀 보행 분석', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildHeader(gaitProvider, theme),
            const SizedBox(height: 20),
            _buildDualTaskToggle(theme),
            const SizedBox(height: 20),
            if (_currentTask != null) _buildTaskBanner(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildLiveChart(gaitProvider, theme),
            ),
            const SizedBox(height: 20),
            _buildControls(gaitProvider),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(GaitProvider provider, ThemeData theme) {
    String minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    String seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.isMeasuring ? '분석 중...' : '준비 완료',
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _isFinished ? '분석 완료' : '$minutes:$seconds',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('감지된 걸음', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
              Text('${provider.steps}보', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChart(GaitProvider provider, ThemeData theme) {
    if (!provider.isMeasuring && provider.liveAccData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_run, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              '분석 시작 버튼을 누르고\n평소처럼 일정하게 걸어주세요',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16, height: 1.5),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('실시간 보행 파형', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: -15,
                maxY: 15,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: provider.liveAccData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(GaitProvider provider) {
    if (_isFinished) {
      return SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('결과 확인 및 종료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: provider.isMeasuring ? _stopAnalysis : _startAnalysis,
        style: ElevatedButton.styleFrom(
          backgroundColor: provider.isMeasuring ? Colors.redAccent : Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          provider.isMeasuring ? '분석 중지' : '분석 시작',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDualTaskToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 12),
              Text('이중 과제 모드 (치매 정밀 진단)', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
            ],
          ),
          Switch(
            value: _isDualTask,
            onChanged: (value) => setState(() => _isDualTask = value),
            activeThumbColor: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.4), blurRadius: 15)],
      ),
      child: Column(
        children: [
          const Text('지금 수행할 인지 미션', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _currentTask!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
