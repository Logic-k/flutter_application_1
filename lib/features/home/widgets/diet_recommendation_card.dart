import 'package:flutter/material.dart';

class DietRecommendationCard extends StatelessWidget {
  const DietRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 오늘의 추천 식품 데이터 (매일 변경되는 시나리오 가정)
    final recommendations = [
      {
        "food": "블루베리",
        "reason": "항산화 성분이 풍부하여 뇌세포 손상을 방지합니다.",
        "recipe": "요거트에 생 블루베리를 섞어서 드세요.",
        "icon": Icons.eco_outlined,
        "color": Colors.indigo,
      },
      {
        "food": "호두 & 견과류",
        "reason": "오메가-3가 풍부해 인지 기능 유지에 도움을 줍니다.",
        "recipe": "하루 한 줌, 간식 대용으로 섭취하세요.",
        "icon": Icons.bakery_dining_outlined,
        "color": Colors.brown,
      },
      {
        "food": "시금치",
        "reason": "엽산이 풍부해 뇌 신경 전달 물질 생성을 돕습니다.",
        "recipe": "들기름에 가볍게 무쳐 나물로 드세요.",
        "icon": Icons.grass_outlined,
        "color": Colors.green,
      },
      {
        "food": "고등어",
        "reason": "DHA와 EPA가 풍부해 기억력 향상에 좋습니다.",
        "recipe": "주 2회 구이나 조림으로 섭취하세요.",
        "icon": Icons.sailing_outlined,
        "color": Colors.blue,
      }
    ];

    // 날짜 기반으로 추천 식품 선택
    final dayIndex = DateTime.now().day % recommendations.length;
    final item = recommendations[dayIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (item['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (item['color'] as Color).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item['icon'] as IconData, color: item['color'] as Color),
              const SizedBox(width: 8),
              Text(
                '오늘의 뇌 건강 식품',
                style: TextStyle(
                  color: item['color'] as Color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${item['food']}를 추천합니다',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            item['reason'].toString(),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.restaurant_menu, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '간단 레시피: ${item['recipe']}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
