class QuestionType {
  final String id;
  final String name; // 'mcq', 'match_following', 'fill_blank'
  final DateTime createdAt;

  QuestionType({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory QuestionType.fromJson(Map<String, dynamic> json) {
    return QuestionType(
      id: json['id'] ?? '',
      name: json['type'] ?? json['name'] ?? 'mcq',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Question {
  final String id;
  final String? typeId;
  final String? category;
  final String? subcategory;
  final String title;
  final String? description;
  final List<String>? tags;
  final String? departmentId;
  final String? difficulty; // 'easy', 'medium', 'hard'
  final int points;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.id,
    this.typeId,
    this.category,
    this.subcategory,
    required this.title,
    this.description,
    this.tags,
    this.departmentId,
    this.difficulty,
    this.points = 10,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      typeId: json['type_id'],
      category: json['category'],
      subcategory: json['subcategory'],
      title: json['title'] ?? 'Question',
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      departmentId: json['dept_id'] ?? json['department_id'],
      difficulty: json['difficulty'],
      points: json['points'] ?? 10,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type_id': typeId,
      'category': category,
      'subcategory': subcategory,
      'title': title,
      'description': description,
      'tags': tags,
      'dept_id': departmentId,
      'difficulty': difficulty,
      'points': points,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class QuestionOption {
  final String id;
  final String questionId;
  final int subQuestionNumber;
  final String optionText;
  final bool isCorrect;
  final String? matchPairLeft;
  final String? matchPairRight;
  final DateTime createdAt;

  QuestionOption({
    required this.id,
    required this.questionId,
    this.subQuestionNumber = 1,
    required this.optionText,
    this.isCorrect = false,
    this.matchPairLeft,
    this.matchPairRight,
    required this.createdAt,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] ?? '',
      questionId: json['question_id'] ?? '',
      subQuestionNumber: json['sub_question_number'] ?? 1,
      optionText: json['option_text'] ?? '',
      isCorrect: json['is_correct'] ?? false,
      matchPairLeft: json['match_pair_left'],
      matchPairRight: json['match_pair_right'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'sub_question_number': subQuestionNumber,
      'option_text': optionText,
      'is_correct': isCorrect,
      'match_pair_left': matchPairLeft,
      'match_pair_right': matchPairRight,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
