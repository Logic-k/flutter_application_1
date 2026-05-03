import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/user_provider.dart';
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
      await _audioPlayer.play(
        UrlSource('https://assets.mixkit.co/sfx/preview/mixkit-forest-birds-chirping-1211.mp3'),
      );
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
    int month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  Map<String, dynamic> _getSeasonData(String season) {
    switch (season) {
      case 'spring':
        return {
          'title': '따스한 봄볕 아래 정원이 깨어나고 있어요',
          'color': Colors.pink.shade50,
          'flower': '벚꽃',
          'animation': 'https://lottie.host/df676767-1724-469b-90f3-8555e101f301/Y1J7XW1Nq1.json', // 꽃 피는 애니메이션 예시
        };
      case 'summer':
        return {
          'title': '푸른 여름 정원이 활기차게 자라고 있습니다',
          'color': Colors.blue.shade50,
          'flower': '라벤더',
          'animation': 'https://lottie.host/79a8383e-1b32-4467-889a-0e7845f94d33/7K9Y1V5Y0f.json',
        };
      case 'autumn':
        return {
          'title': '풍성한 가을 정원이 황금빛으로 물들었네요',
          'color': Colors.orange.shade50,
          'flower': '단풍',
          'animation': 'https://lottie.host/df676767-1724-469b-90f3-8555e101f301/Y1J7XW1Nq1.json',
        };
      default:
        return {
          'title': '고요한 겨울 정원이 눈과 함께 쉬고 있어요',
          'color': Colors.blueGrey.shade50,
          'flower': '설중매',
          'animation': 'https://lottie.host/703668e2-0f02-4fc9-9d7a-75179ee41d7d/U8yD6Y7Y0f.json',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();
    final pedometer = context.watch<PedometerManager>();
    
    String season = _getSeasonName();
    var seasonData = _getSeasonData(season);

    double stepProgress = (pedometer.todaySteps / 10000).clamp(0.0, 1.0);
    double cognitiveProgress = ((user.calculationScore + user.logicScore + user.memoryScore + user.attentionScore) / 400.0).clamp(0.0, 1.0);
    double totalProgress = (stepProgress + cognitiveProgress) / 2.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('기억의 정원'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isHealingSoundOn ? Icons.volume_up : Icons.volume_off),
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (seasonData['color'] as Color).withValues(alpha: 0.3),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                totalProgress >= 0.8 ? '정원이 활기차게 피어났습니다!' : seasonData['title'],
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '현재 제철 꽃: ${seasonData['flower']}',
              style: TextStyle(color: theme.primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _shakeController.forward(from: 0);
                    // 터치 시 효과음이나 반짝임 로직 추가 가능
                  },
                  child: RotationTransition(
                    turns: Tween(begin: -0.01, end: 0.01).animate(_shakeController),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (totalProgress > 0.5)
                          Lottie.network(
                            'https://lottie.host/703668e2-0f02-4fc9-9d7a-75179ee41d7d/U8yD6Y7Y0f.json',
                            width: 400,
                            repeat: true,
                          ),
                        
                        Lottie.network(
                          totalProgress < 0.3 
                            ? 'https://lottie.host/df676767-1724-469b-90f3-8555e101f301/Y1J7XW1Nq1.json'
                            : seasonData['animation'],
                          width: 350,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.local_florist, size: 100, color: theme.primaryColor.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildProgressCard(theme, stepProgress, cognitiveProgress),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme, double steps, double cognitive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _buildProgressBar('신체 활동 (걸음 수)', steps, Colors.orange.shade600),
          const SizedBox(height: 20),
          _buildProgressBar('두뇌 훈련 (정답률)', cognitive, Colors.blue.shade600),
          const SizedBox(height: 16),
          Text(
            '조금 더 힘내시면 정원의 꽃이 더 활짝 피어납니다!',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 12,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
