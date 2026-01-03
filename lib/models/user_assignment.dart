class UserAssignment {
  final String id;
  final String userId;
  final String pathwayId; // dept_id from user_pathway table
  final String assignmentName;
  final bool orientationCompleted;
  final int marks;
  final int maxMarks;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isCurrent;

  UserAssignment({
    required this.id,
    required this.userId,
    required this.pathwayId,
    required this.assignmentName,
    this.orientationCompleted = false,
    this.marks = 0,
    this.maxMarks = 100,
    this.isCurrent = true,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'assignment_name': assignmentName,
      'orientation_completed': orientationCompleted,
      'marks': marks,
      'max_marks': maxMarks,
      'is_current': isCurrent,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserAssignment.fromJson(Map<String, dynamic> json) {
    return UserAssignment(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      pathwayId: json['pathway_id']?.toString() ?? '', // Fixed: use pathway_id not dept_id
      assignmentName: json['assignment_name'] ?? json['pathway_name'] ?? 'Unnamed Assignment',
      orientationCompleted: json['orientation_completed'] ?? false,
      marks: json['marks'] ?? 0,
      maxMarks: json['max_marks'] ?? 100,
      isCurrent: json['is_current'] ?? true,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? json['enrolled_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isCompleted => completedAt != null;
  
  double get percentage => maxMarks > 0 ? (marks / maxMarks) * 100 : 0;
  
  String get status {
    if (isCompleted) return 'Completed';
    return 'Pending';
  }
}
