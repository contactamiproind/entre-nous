import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  final _supabase = Supabase.instance.client;

  // Save user's answer to a question
  Future<void> saveQuestionAnswer({
    required String userId,
    required String departmentId,
    required String usrDeptId,
    required String questionId,
    required String userAnswer,
    required bool isCorrect,
    required int scoreEarned,
  }) async {
    await _supabase.from('usr_progress').upsert({
      'user_id': userId,
      'dept_id': departmentId,
      'usr_dept_id': usrDeptId,
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
      'score_earned': scoreEarned,
      'status': 'answered',
      'last_attempted_at': DateTime.now().toIso8601String(),
    }, onConflict: 'usr_dept_id,question_id');
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
        .from('usr_progress')
        .select()
        .eq('user_id', userId)
        .eq('dept_id', departmentId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  // Check if user has already answered a question
  Future<bool> hasAnsweredQuestion({
    required String userId,
    required String questionId,
  }) async {
    final response = await _supabase
        .from('usr_progress')
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
    try {
      // Query from usr_dept for current active department
      final response = await _supabase
          .from('usr_dept')
          .select()
          .eq('user_id', userId)
          .eq('is_current', true)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ User progress error ignored: $e');
      return null;
    }
  }
}
