/// Stable metadata for one training activity.
class TrainingActivity {
  const TrainingActivity({
    required this.id,
    required this.displayArea,
    required this.route,
    required this.adaptiveCategory,
    required this.scoreCategory,
    required this.prerequisiteId,
    required this.isAlwaysUnlocked,
  });

  final String id;
  final String displayArea;
  final String route;

  /// Category used by the existing adaptive difficulty feature.
  final String? adaptiveCategory;

  /// Cognitive score category updated by a scored completion.
  final String? scoreCategory;

  /// Activity that must be completed once before this activity unlocks.
  final String? prerequisiteId;

  /// Whether the activity remains available independently of unlock records.
  final bool isAlwaysUnlocked;

  bool get isParticipationOnly => scoreCategory == null;
}
