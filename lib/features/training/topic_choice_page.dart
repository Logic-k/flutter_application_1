import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import 'application/training_attempt_input.dart';
import 'application/training_completion_ui.dart';
import 'training_progress_provider.dart';
import 'widgets/game_template.dart';

class TopicChoicePage extends StatefulWidget {
  const TopicChoicePage({super.key});

  @override
  State<TopicChoicePage> createState() => _TopicChoicePageState();
}

class _TopicChoicePageState extends State<TopicChoicePage> {
  static const _contentVersion = 'topic_choice_v1';

  static const _topics = <_TopicOption>[
    _TopicOption('meal', '좋아하는 음식', Icons.restaurant_rounded),
    _TopicOption('season', '좋아하는 계절', Icons.wb_sunny_rounded),
    _TopicOption('hobby', '편안한 취미', Icons.palette_rounded),
  ];

  static const _assistanceOptions = <_AssistanceOption>[
    _AssistanceOption('혼자 했어요', TrainingAssistanceLevel.independent),
    _AssistanceOption('말로 설명을 들었어요', TrainingAssistanceLevel.verbalPrompt),
    _AssistanceOption('직접 조작 도움을 받았어요', TrainingAssistanceLevel.handsOnHelp),
  ];

  late final String _attemptId;
  late final DateTime _startedAt;
  String? _selectedTopicId;
  String _assistanceLevel = TrainingAssistanceLevel.independent;
  bool _isSaving = false;
  TrainingAttemptInput? _completionInput;

  @override
  void initState() {
    super.initState();
    _attemptId = createTrainingAttemptId();
    _startedAt = DateTime.now();
  }

  Future<void> _submitCompletion() async {
    if (_isSaving) return;
    if (_selectedTopicId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘 이야기할 주제를 하나 골라주세요.')));
      return;
    }

    final progress = context.read<TrainingProgressProvider>();
    final userId = progress.userId;
    if (userId == null) {
      _showSaveFailure();
      return;
    }

    final completedAt = DateTime.now();
    _completionInput ??= TrainingAttemptInput(
      attemptId: _attemptId,
      userId: userId,
      activityId: 'topic_choice',
      completedAt: completedAt,
      durationMs: completedAt.difference(_startedAt).inMilliseconds,
      completionStatus: TrainingCompletionStatus.completed,
      assistanceLevel: _assistanceLevel,
      sessionContext: TrainingSessionContext.selfPractice,
      contentVersion: _contentVersion,
      responseCode: _selectedTopicId,
    );

    setState(() => _isSaving = true);
    try {
      final result = await progress.complete(_completionInput!);
      if (!mounted) return;
      await showTrainingCompletionResult(context, result);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSaveFailure();
    }
  }

  void _showSaveFailure() {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('기록을 저장하지 못했습니다. 다시 시도해 주세요.'),
        action: SnackBarAction(label: '다시 시도', onPressed: _submitCompletion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameTemplate(
      title: '함께 고르는 한 주제',
      objective: '정답을 맞히는 검사가 아니라\n선택과 도움 정도를 남기는 활동이에요.',
      currentStep: _selectedTopicId == null ? 1 : 2,
      totalSteps: 2,
      adaptiveCategory: null,
      activityId: 'topic_choice',
      child: ListView(
        children: [
          const SizedBox(height: 20),
          Text(
            '1. 오늘 이야기하고 싶은 주제',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final topic in _topics)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TopicCard(
                option: topic,
                selected: _selectedTopicId == topic.id,
                enabled: !_isSaving && _completionInput == null,
                onTap: () => setState(() => _selectedTopicId = topic.id),
              ),
            ),
          const SizedBox(height: 16),
          _PromptBox(topicId: _selectedTopicId),
          const SizedBox(height: 16),
          Text(
            '3. 도움 정도',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _assistanceOptions)
                ChoiceChip(
                  label: Text(option.label),
                  selected: _assistanceLevel == option.value,
                  onSelected: (_isSaving || _completionInput != null)
                      ? null
                      : (_) => setState(() => _assistanceLevel = option.value),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submitCompletion,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.scheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.rTile),
                ),
              ),
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '활동 기록하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptBox extends StatelessWidget {
  const _PromptBox({required this.topicId});

  final String? topicId;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.rTile),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. 짧게 떠올려 보기',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _promptFor(topicId),
            style: TextStyle(
              height: 1.5,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '대화 내용은 앱에 저장하지 않고, 선택한 주제와 도움 정도만 기록합니다.',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _promptFor(String? topicId) => switch (topicId) {
    'meal' => '좋아하는 음식을 떠올리고, 누구와 함께 먹고 싶은지 말하거나 마음속으로 골라보세요.',
    'season' => '좋아하는 계절을 떠올리고, 그 계절에 하고 싶은 일을 하나 골라보세요.',
    'hobby' => '편안한 취미를 떠올리고, 시작할 때 필요한 물건이나 장소를 하나 골라보세요.',
    _ => '먼저 주제를 고른 뒤, 생각나는 이유나 함께 나누고 싶은 상황을 짧게 떠올려보세요.',
  };
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final _TopicOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.rTile),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.rTile),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.rTile),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                option.icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicOption {
  const _TopicOption(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

class _AssistanceOption {
  const _AssistanceOption(this.label, this.value);

  final String label;
  final String value;
}
