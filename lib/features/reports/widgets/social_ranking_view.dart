import 'dart:math' as math;
import 'package:flutter/material.dart';

class SocialRankingView extends StatelessWidget {
  final double userScore;
  final String categoryName;

  const SocialRankingView({
    super.key,
    required this.userScore,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 60~70대 평균 기준 (학술 자료 기반 추정값)
    const double avgScore = 65.0;
    const double stdDev = 15.0;

    // 정규 분포 근사 백분위 계산
    final double z = (userScore - avgScore) / stdDev;
    int percentile = _zToPercentile(z).clamp(1, 99);

    final bool aboveAverage = userScore >= avgScore;
    final double barPosition = (userScore / 100.0).clamp(0.0, 1.0);
    final double avgBarPosition = avgScore / 100.0;

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
          Text(
            '인구 통계학적 비교 ($categoryName)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '비슷한 연령대(60~70대) 사용자와 비교한 수치입니다.',
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 32),

          // LayoutBuilder로 실제 너비를 기반으로 마커 위치 계산
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
                            '${userScore.toStringAsFixed(0)}점',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 2,
                          height: 8,
                          color: Colors.black87,
                        ),
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
                '동연령대 평균 ${avgScore.toInt()}점',
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

  /// Z-점수를 백분위로 근사 변환 (정규 분포)
  int _zToPercentile(double z) {
    // 누적 정규 분포 근사 (Horner's method)
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
