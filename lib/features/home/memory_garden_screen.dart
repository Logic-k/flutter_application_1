import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/user_provider.dart';
import '../../core/ml_widgets.dart';
import '../../core/theme.dart';
import '../gait_analysis/pedometer_manager.dart';

class MemoryGardenScreen extends StatefulWidget {
  const MemoryGardenScreen({super.key});

  @override
  State<MemoryGardenScreen> createState() => _MemoryGardenScreenState();
}

class _MemoryGardenScreenState extends State<MemoryGardenScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _shakeController;
  bool _isHealingSoundOn = true;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _playAmbientSound();
  }

  Future<void> _playAmbientSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/sfx/preview/mixkit-forest-birds-chirping-1211.mp3'));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String _getSeasonName() {
    final m = DateTime.now().month;
    if (m >= 3 && m <= 5) return 'spring';
    if (m >= 6 && m <= 8) return 'summer';
    if (m >= 9 && m <= 11) return 'autumn';
    return 'winter';
  }

  Map<String, dynamic> _getSeasonData(String season) {
    switch (season) {
      case 'spring':
        return {'title': '따스한 봄볕 아래 정원이 깨어나고 있어요', 'color': const Color(0xFFFCE4EC), 'flower': '벚꽃', 'animation': 'https://lottie.host/df676767-1724-469b-90f3-8555e101f301/Y1J7XW1Nq1.json'};
      case 'summer':
        return {'title': '푸른 여름 정원이 활기차게 자라고 있습니다', 'color': const Color(0xFFE3F2FD), 'flower': '라벤더', 'animation': 'https://lottie.host/79a8383e-1b32-4467-889a-0e7845f94d33/7K9Y1V5Y0f.json'};
      case 'autumn':
        return {'title': '풍성한 가을 정원이 황금빛으로 물들었네요', 'color': const Color(0xFFFFF3E0), 'flower': '단풍', 'animation': 'https://lottie.host/df676767-1724-469b-90f3-8555e101f301/Y1J7XW1Nq1.json'};
      default:
        return {'title': '고요한 겨울 정원이 눈과 함께 쉬고 있어요', 'color': const Color(0xFFECEFF1), 'flower': '설중매', 'animation': 'https://lottie.host/703668e2-0f02-4fc9-9d7a-75179ee41d7d/U8yD6Y7Y0f.json'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final pedometer = context.watch<PedometerManager>();

    final season = _getSeasonName();
    final seasonData = _getSeasonData(season);
    final stepProgress = (pedometer.todaySteps / 10000).clamp(0.0, 1.0);
    final cognitiveProgress = ((user.calculationScore + user.logicScore + user.memoryScore + user.attentionScore) / 400.0).clamp(0.0, 1.0);
    final totalProgress = (stepProgress + cognitiveProgress) / 2.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('기억의 정원'),
        actions: [
          IconButton(
            icon: Icon(_isHealingSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded),
            onPressed: () {
              setState(() {
                _isHealingSoundOn = !_isHealingSoundOn;
                _isHealingSoundOn ? _audioPlayer.resume() : _audioPlayer.pause();
              });
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [(seasonData['color'] as Color).withValues(alpha: 0.4), MLColors.bg],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                totalProgress >= 0.8 ? '정원이 활기차게 피어났습니다!' : seasonData['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Text('현재 제철 꽃: ${seasonData['flower']}', style: const TextStyle(color: MLColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => _shakeController.forward(from: 0),
                  child: RotationTransition(
                    turns: Tween(begin: -0.01, end: 0.01).animate(_shakeController),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (totalProgress > 0.5)
                          Lottie.network(
                            'https://lottie.host/703668e2-0f02-4fc9-9d7a-75179ee41d7d/U8yD6Y7Y0f.json',
                            width: 400, repeat: true,
                            errorBuilder: (ctx, e, s) => const SizedBox.shrink(),
                          ),
                        Lottie.network(
                          totalProgress < 0.3 ? 'https://lottie.host/df676767-1724-469b-90f3-8555e101f301/Y1J7XW1Nq1.json' : seasonData['animation'] as String,
                          width: 350, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_florist_rounded, size: 100, color: MLColors.mem),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildProgressCard(stepProgress, cognitiveProgress),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(double steps, double cognitive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: MLCard(
        child: Column(
          children: [
            _buildProgressRow('신체 활동 (걸음 수)', steps, MLColors.read),
            const SizedBox(height: 16),
            _buildProgressRow('두뇌 훈련 (정답률)', cognitive, MLColors.calc),
            const SizedBox(height: 12),
            const Text('조금 더 힘내시면 정원의 꽃이 더 활짝 피어납니다!', style: TextStyle(fontSize: 12, color: MLColors.textSoft)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        MLProgressBar(value: value, color: color),
      ],
    );
  }
}
