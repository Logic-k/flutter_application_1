import 'training_activity.dart';

const List<TrainingActivity> trainingCatalog = <TrainingActivity>[
  TrainingActivity(
    id: 'comparison',
    displayArea: '계산',
    route: '/game/comparison',
    adaptiveCategory: 'calculation',
    scoreCategory: 'calculation',
    prerequisiteId: null,
    isAlwaysUnlocked: false,
  ),
  TrainingActivity(
    id: 'multiplication',
    displayArea: '계산',
    route: '/game/multiplication',
    adaptiveCategory: 'calculation',
    scoreCategory: 'calculation',
    prerequisiteId: 'comparison',
    isAlwaysUnlocked: false,
  ),
  TrainingActivity(
    id: 'sequence',
    displayArea: '논리',
    route: '/game/sequence',
    adaptiveCategory: 'logic',
    scoreCategory: 'logic',
    prerequisiteId: null,
    isAlwaysUnlocked: false,
  ),
  TrainingActivity(
    id: 'categorization',
    displayArea: '논리',
    route: '/game/categorization',
    adaptiveCategory: 'logic',
    scoreCategory: 'logic',
    prerequisiteId: 'sequence',
    isAlwaysUnlocked: false,
  ),
  TrainingActivity(
    id: 'shape_sudoku',
    displayArea: '기억',
    route: '/game/sudoku',
    adaptiveCategory: 'memory',
    scoreCategory: 'memory',
    prerequisiteId: null,
    isAlwaysUnlocked: false,
  ),
  TrainingActivity(
    id: 'shape_match',
    displayArea: '지각',
    route: '/game/shape_match',
    adaptiveCategory: 'perception',
    scoreCategory: 'attention',
    prerequisiteId: null,
    isAlwaysUnlocked: false,
  ),
  TrainingActivity(
    id: 'sentence_reading',
    displayArea: '언어',
    route: '/game/reading',
    adaptiveCategory: 'perception',
    scoreCategory: 'voice',
    prerequisiteId: 'shape_match',
    isAlwaysUnlocked: false,
  ),
  TrainingActivity(
    id: 'daily_recall',
    displayArea: '스마트 케어',
    route: '/training/recall',
    adaptiveCategory: null,
    scoreCategory: null,
    prerequisiteId: null,
    isAlwaysUnlocked: true,
  ),
];

const Set<String> initialTrainingActivityIds = <String>{
  'comparison',
  'sequence',
  'shape_sudoku',
  'shape_match',
  'daily_recall',
};

const Set<String> legacyTrainingActivityIds = <String>{
  'comparison',
  'multiplication',
  'sequence',
  'categorization',
  'shape_sudoku',
  'shape_match',
  'sentence_reading',
  'daily_recall',
};

final Map<String, TrainingActivity> _trainingActivitiesById =
    <String, TrainingActivity>{
      for (final activity in trainingCatalog) activity.id: activity,
    };

bool isKnownTrainingActivity(String id) =>
    _trainingActivitiesById.containsKey(id);

TrainingActivity trainingActivityById(String id) {
  final activity = _trainingActivitiesById[id];
  if (activity == null) {
    throw ArgumentError.value(id, 'id', 'Unknown training activity');
  }
  return activity;
}
