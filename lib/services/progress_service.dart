import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  final _supabase = Supabase.instance.client;

  // Save user's answer to a question
  Future<void> saveQuestionAnswer({
    required String userId,
    required String departmentId,
    required String questionId,
    required int questionOrder,
    required Map<String, dynamic> userAnswer,
    required bool isCorrect,
    required int pointsEarned,
  }) async {
    await _supabase.from('usr_stat').insert({
      'user_id': userId,
      'department_id': departmentId,
      'question_id': questionId,
      'question_order': questionOrder,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
      'points_earned': pointsEarned,
    });
  }

  // Get user's progress summary for a department
  Future<Map<String, dynamic>?> getUserProgressSummary({
    required String userId,
    required String departmentId,
  }) async {
    final response = await _supabase
        .from('usr_dept')
        .select()
        .eq('user_id', userId)
        .eq('dept_id', departmentId)
        .maybeSingle();

    return response;
  }

  // Get all answers for a specific quiz session
  Future<List<Map<String, dynamic>>> getQuizAnswers({
    required String userId,
    required String departmentId,
  }) async {
    final response = await _supabase
        .from('usr_stat')
        .select()
        .eq('user_id', userId)
        .eq('department_id', departmentId)
        .order('question_order');

    return List<Map<String, dynamic>>.from(response);
  }

  // Check if user has already answered a question
  Future<bool> hasAnsweredQuestion({
    required String userId,
    required String questionId,
  }) async {
    final response = await _supabase
        .from('usr_stat')
        .select()
        .eq('user_id', userId)
        .eq('question_id', questionId)
        .maybeSingle();

    return response != null;
  }

  // Get user's overall statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final summaries = await _supabase
        .from('usr_dept')
        .select()
        .eq('user_id', userId);

    final summaryList = List<Map<String, dynamic>>.from(summaries);

    if (summaryList.isEmpty) {
      return {
        'total_questions': 0,
        'correct_answers': 0,
        'total_score': 0,
        'average_accuracy': 0.0,
      };
    }

    int totalQuestions = 0;
    int correctAnswers = 0;
    int totalScore = 0;

    for (var summary in summaryList) {
      totalQuestions += (summary['total_questions'] as int?) ?? 0;
      correctAnswers += (summary['correct_answers'] as int?) ?? 0;
      totalScore += (summary['total_score'] as int?) ?? 0;
    }

    return {
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'total_score': totalScore,
      'average_accuracy': totalQuestions > 0 
          ? (correctAnswers / totalQuestions * 100).toStringAsFixed(2)
          : '0.00',
    };
  }

  // Get all user progress (for admin dashboard)
  Future<List<Map<String, dynamic>>> getAllUserProgress() async {
    final response = await _supabase
        .from('usr_dept')
        .select();

    return List<Map<String, dynamic>>.from(response);
  }

  // Get user progress (current department)
  Future<Map<String, dynamic>?> getUserProgress(String userId) async {
    // Query from usr_dept for current active department
    final response = await _supabase
        .from('usr_dept')
        .select()
        .eq('user_id', userId)
        .eq('is_current', true)
        .maybeSingle();

    return response;
  }
}
