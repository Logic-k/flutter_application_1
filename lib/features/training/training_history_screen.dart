import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/ml_widgets.dart';
import '../../core/theme.dart';
import 'application/training_completion_ui.dart';
import 'data/training_progress_repository.dart';
import 'training_progress_provider.dart';

/// 나의 훈련 기록 — `training_attempts`에 쌓이는 완료 시도를 날짜별로 보여준다.
///
/// 이 데이터는 저장만 되고 읽는 화면이 없었다(getAttempts 호출자 0건).
/// 점수가 없는 활동(일상 회상)은 점수 대신 완료 사실만 표시한다.
class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  late Future<List<TrainingAttemptRecord>> _future;
  String? _activityFilter;

  @override
  void initState() {
    super.initState();
    _future = context.read<TrainingProgressProvider>().getAttempts();
  }

  void _reload() {
    setState(() {
      _future = context.read<TrainingProgressProvider>().getAttempts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나의 훈련 기록')),
      body: FutureBuilder<List<TrainingAttemptRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return MLErrorState(onRetry: _reload);
          }
          final attempts = (snapshot.data ?? const [])
              .reversed // 저장소는 오름차순 — 화면은 최신 먼저
              .toList();
          if (attempts.isEmpty) {
            return const _EmptyHistory();
          }

          final activityIds = <String>{
            for (final a in attempts)
              if (isKnownActivity(a.activityId)) a.activityId,
          };

          final filtered = _activityFilter == null
              ? attempts
              : attempts
                  .where((a) => a.activityId == _activityFilter)
                  .toList();

          // localDate(YYYY-MM-DD)로 묶어 날짜 헤더를 만든다.
          final grouped = <String, List<TrainingAttemptRecord>>{};
          for (final a in filtered) {
            (grouped[a.localDate] ??= []).add(a);
          }
          final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              if (activityIds.length > 1)
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('전체'),
                          selected: _activityFilter == null,
                          onSelected: (_) =>
                              setState(() => _activityFilter = null),
                        ),
                      ),
                      for (final id in activityIds)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(trainingActivityName(id)),
                            selected: _activityFilter == id,
                            onSelected: (selected) => setState(
                              () => _activityFilter = selected ? id : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: dates.length,
                  itemBuilder: (context, i) {
                    final date = dates[i];
                    final dayAttempts = grouped[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            _formatDate(date),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        for (final a in dayAttempts) _AttemptTile(attempt: a),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // intl locale 데이터 없이도 동작하도록 고정 한국어 형식으로 포맷한다.
  String _formatDate(String localDate) {
    final parsed = DateTime.tryParse(localDate);
    if (parsed == null) return localDate;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${parsed.month}월 ${parsed.day}일 (${weekdays[parsed.weekday - 1]})';
  }
}

bool isKnownActivity(String activityId) {
  try {
    trainingActivityName(activityId);
    return true;
  } on ArgumentError {
    return false;
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt});

  final TrainingAttemptRecord attempt;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final name = isKnownActivity(attempt.activityId)
        ? trainingActivityName(attempt.activityId)
        : attempt.activityId;

    final completedAt = DateTime.tryParse(attempt.completedAt);
    final timeText = completedAt != null
        ? '${completedAt.hour.toString().padLeft(2, '0')}:'
            '${completedAt.minute.toString().padLeft(2, '0')}'
        : '';

    final details = <String>[
      if (attempt.score != null) '점수 ${attempt.score!.round()}점',
      if (attempt.correctAnswers != null && attempt.totalQuestions != null)
        '${attempt.correctAnswers}/${attempt.totalQuestions} 정답',
      if (attempt.durationMs != null)
        '${(attempt.durationMs! / 1000).round()}초',
    ];

    return MLCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                if (details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      details.join(' · '),
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${Fmt.count(attempt.xpEarned)} XP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              if (timeText.isNotEmpty)
                Text(
                  timeText,
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: 64, color: context.scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            '아직 완료한 훈련이 없습니다.\n트레이닝 센터에서 첫 활동을 시작해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
