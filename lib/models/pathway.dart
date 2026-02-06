class Pathway {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pathway({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper to display department name with category for "General" departments
  String get displayName {
    if (title == 'General' && category != null && category!.isNotEmpty) {
      return 'General ($category)';
    }
    return title;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Pathway.fromJson(Map<String, dynamic> json) {
    return Pathway(
      id: json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? 'Unknown',
      description: json['description'],
      category: json['category'],
      displayOrder: json['display_order'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
}

class PathwayLevel {
  final String id;
  final String pathwayId;
  final String? levelId;
  final int levelNumber;
  final String levelName;
  final String? category;
  final int requiredScore;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  PathwayLevel({
    required this.id,
    required this.pathwayId,
    this.levelId,
    required this.levelNumber,
    required this.levelName,
    this.category,
    required this.requiredScore,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dept_id': pathwayId,
      'level_id': levelId,
      'level_number': levelNumber,
      'title': levelName,
      'category': category,
      'required_score': requiredScore,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PathwayLevel.fromJson(Map<String, dynamic> json) {
    // Safely extract values with proper null handling
    final id = json['id'];
    final deptId = json['dept_id'] ?? json['pathway_id'] ?? json['department_id'];
    final title = json['title'] ?? json['level_name'];
    
    return PathwayLevel(
      id: id != null ? id.toString() : '',
      pathwayId: deptId != null ? deptId.toString() : '',
      levelId: json['level_id']?.toString(),
      levelNumber: json['level_number'] is int ? json['level_number'] : int.tryParse(json['level_number']?.toString() ?? '1') ?? 1,
      levelName: title != null ? title.toString() : 'Level ${json['level_number'] ?? 1}',
      category: json['category']?.toString(),
      requiredScore: json['required_score'] is int ? json['required_score'] : int.tryParse(json['required_score']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}
