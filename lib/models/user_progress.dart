class UserProgress {
  final String id;
  final String userId;
  final int totalAssignments;
  final int completedAssignments;
  final int totalMarks;
  final bool orientationCompleted;
  final String? currentPathwayId;
  final int currentLevel;
  final int currentScore;
  final DateTime updatedAt;

  UserProgress({
    required this.id,
    required this.userId,
    this.totalAssignments = 0,
    this.completedAssignments = 0,
    this.totalMarks = 0,
    this.orientationCompleted = false,
    this.currentPathwayId,
    this.currentLevel = 1,
    this.currentScore = 0,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_assignments': totalAssignments,
      'completed_assignments': completedAssignments,
      'total_marks': totalMarks,
      'orientation_completed': orientationCompleted,
      'current_pathway_id': currentPathwayId,
      'current_level': currentLevel,
      'current_score': currentScore,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'],
      userId: json['user_id'],
      totalAssignments: json['total_assignments'] ?? 0,
      completedAssignments: json['completed_assignments'] ?? 0,
      totalMarks: json['total_marks'] ?? 0,
      orientationCompleted: json['orientation_completed'] ?? false,
      currentPathwayId: json['current_pathway_id'],
      currentLevel: json['current_level'] ?? 1,
      currentScore: json['current_score'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  double get completionPercentage {
    if (totalAssignments == 0) return 0;
    return (completedAssignments / totalAssignments) * 100;
  }

  int get pendingAssignments => totalAssignments - completedAssignments;

  bool get hasPathway => currentPathwayId != null;
  
  bool get canSelectPathway => orientationCompleted && !hasPathway;
}
