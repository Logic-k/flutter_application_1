import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SocialRankingView extends StatefulWidget {
  final double userScore;
  final String categoryName;

  const SocialRankingView({
    super.key,
    required this.userScore,
    required this.categoryName,
  });

  @override
  State<SocialRankingView> createState() => _SocialRankingViewState();
}

class _SocialRankingViewState extends State<SocialRankingView> {
  // 기본값: 학술 자료 기반 60~70대 추정값
  double _avgScore = 65.0;
  double _stdDev = 15.0;
  bool _loaded = false;

  static const _categoryKeyMap = {
    '기억력': 'memory',
    '계산력': 'calculation',
    '논리력': 'logic',
    '집중력': 'attention',
  };

  @override
  void initState() {
    super.initState();
    _loadGlobalStats();
  }

  Future<void> _loadGlobalStats() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('global_stats')
          .doc('score_stats')
          .get();

      if (!snap.exists || !mounted) return;

      final data = snap.data()!;
      final firestoreKey = _categoryKeyMap[widget.categoryName];
      final catStats = data['category_stats'] as Map<String, dynamic>?;

      double avg = (data['avg_score'] as num?)?.toDouble() ?? 65.0;
      double std = (data['std_dev'] as num?)?.toDouble() ?? 15.0;

      if (firestoreKey != null && catStats != null && catStats.containsKey(firestoreKey)) {
        final cat = catStats[firestoreKey] as Map<String, dynamic>;
        avg = (cat['avg'] as num?)?.toDouble() ?? avg;
        std = (cat['std_dev'] as num?)?.toDouble() ?? std;
      }

      setState(() {
        _avgScore = avg;
        _stdDev = std.clamp(1.0, 30.0);
        _loaded = true;
      });
    } catch (_) {
      // 로드 실패 시 기본값(65.0 / 15.0) 유지
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double z = (widget.userScore - _avgScore) / _stdDev;
    final int percentile = _zToPercentile(z).clamp(1, 99);
    final bool aboveAverage = widget.userScore >= _avgScore;
    final double barPosition = (widget.userScore / 100.0).clamp(0.0, 1.0);
    final double avgBarPosition = (_avgScore / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '인구 통계학적 비교 (${widget.categoryName})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (!_loaded)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '비슷한 연령대(60~70대) 사용자와 비교한 수치입니다.',
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 배경 그라디언트 바
                  Container(
                    height: 40,
                    width: totalWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade300,
                          theme.primaryColor.withValues(alpha: 0.4),
                          theme.primaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  // 평균 표시선
                  Positioned(
                    left: totalWidth * avgBarPosition - 1,
                    child: Container(
                      width: 2,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  // 내 위치 마커
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    left: (totalWidth * barPosition - 30).clamp(0, totalWidth - 60),
                    top: -18,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            '${widget.userScore.toStringAsFixed(0)}점',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(width: 2, height: 8, color: Colors.black87),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (aboveAverage ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (aboveAverage ? Colors.green : Colors.orange)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '상위 $percentile%',
                  style: TextStyle(
                    color: aboveAverage ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '동연령대 평균 ${_avgScore.toInt()}점',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            aboveAverage
                ? '동년배 중에서 평균보다 높은 수준의 인지 능력을 보여주고 계십니다. 훌륭합니다!'
                : '평균 수준에 도달하기 위해 조금 더 집중 훈련을 해보는 것은 어떨까요?',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  int _zToPercentile(double z) {
    if (z < -3.5) return 1;
    if (z > 3.5) return 99;
    final double absZ = z.abs();
    final double t = 1.0 / (1.0 + 0.2316419 * absZ);
    const List<double> b = [0.319381530, -0.356563782, 1.781477937, -1.821255978, 1.330274429];
    double poly = t * (b[0] + t * (b[1] + t * (b[2] + t * (b[3] + t * b[4]))));
    double phi = 1.0 - poly * _standardNormalPdf(absZ);
    double percentileVal = z >= 0 ? phi * 100 : (1 - phi) * 100;
    return percentileVal.round().clamp(1, 99);
  }

  double _standardNormalPdf(double x) {
    return (1.0 / math.sqrt(2 * math.pi)) * math.exp(-0.5 * x * x);
  }
}
