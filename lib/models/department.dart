class Department {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Department({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['title'] ?? json['name'] ?? 'Unknown Department',
      description: json['description'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
}

class DepartmentLevel {
  final String id;
  final String departmentId;
  final int levelNumber;
  final String levelName;
  final int requiredScore;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  DepartmentLevel({
    required this.id,
    required this.departmentId,
    required this.levelNumber,
    required this.levelName,
    required this.requiredScore,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_id': departmentId,
      'level_number': levelNumber,
      'level_name': levelName,
      'required_score': requiredScore,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DepartmentLevel.fromJson(Map<String, dynamic> json) {
    return DepartmentLevel(
      id: json['id'] ?? '',
      departmentId: json['department_id'] ?? '',
      levelNumber: json['level_number'] ?? 1,
      levelName: json['level_name'] ?? 'Level ${json['level_number'] ?? 1}',
      requiredScore: json['required_score'] ?? 0,
      description: json['description'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
}
