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

  // Check if all questions for a specific level are completed
  Future<bool> isAllQuestionsCompletedForLevel({
    required String userId,
    required String deptId,
    required int level,
  }) async {
    try {
      // 1. Count total questions for this level
      final totalQuestionsRes = await _supabase
          .from('questions')
          .select('id')
          .eq('dept_id', deptId)
          .eq('level', level)
          .count();
      
      final totalQuestions = totalQuestionsRes.count;

      if (totalQuestions == 0) return true; // No questions => considered complete

      // 2. Count answered questions for this level
      // We need to join usr_progress with questions to filter by level
      // Or easier: 
      // Select questions ID where dept_id = X and level = Y
      // Then count how many of those IDs exist in usr_progress with status='answered'
      
      final questions = await _supabase
          .from('questions')
          .select('id')
          .eq('dept_id', deptId)
          .eq('level', level);
          
      final questionIds = List<String>.from(questions.map((q) => q['id']));
      
      if (questionIds.isEmpty) return true;

      final answeredProgress = await _supabase
          .from('usr_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'answered')
          .filter('question_id', 'in', questionIds);
          
      final answeredCount = answeredProgress.length;
      
      return answeredCount >= totalQuestions;
    } catch (e) {
      debugPrint('Error checking question completion: $e');
      return false;
    }
  }

  // Attempt to promote user to next level
  // Returns true if promoted, false otherwise
  Future<bool> attemptLevelPromotion(String userId, String deptId) async {
    try {
      // 1. Get current level
      final usrDept = await _supabase
          .from('usr_dept')
          .select('id, current_level')
          .eq('user_id', userId)
          .eq('dept_id', deptId)
          .single();
          
      final currentLevel = usrDept['current_level'] ?? 1;
      
      // 2. Check if Questions are complete
      final questionsComplete = await isAllQuestionsCompletedForLevel(
        userId: userId, 
        deptId: deptId, 
        level: currentLevel
      );
      
      if (!questionsComplete) {
        debugPrint('Level $currentLevel questions NOT complete.');
        return false;
      }
      
      // 3. Check if End Game is complete
      // First, try to auto-assign it if they are eligible
      // This ensures that if they just finished the last question, they get the end game assigned
      try {
        await _supabase.rpc('check_and_assign_end_game', params: {'p_user_id': userId});
      } catch (e) {
        debugPrint('Error auto-assigning end game: $e');
      }

      // We need EndGameService locally or pass it in. 
      // To avoid circular deps, we can do a direct DB check similar to EndGameService.isLevelCompleted
      // But let's check end_game_assignments directly here for simplicity
      // Assuming 1 active end game per level
      
      bool endGameComplete = false;
      
      // Find active end game for this level
      final endGameConfig = await _supabase
          .from('end_game_configs')
          .select('id')
          .eq('level', currentLevel)
          .eq('is_active', true)
          .maybeSingle();
          
      if (endGameConfig == null) {
        endGameComplete = true; // No end game? Skip it.
      } else {
        final endGameId = endGameConfig['id'];
        final assignment = await _supabase
            .from('end_game_assignments')
            .select('completed_at')
            .eq('user_id', userId)
            .eq('end_game_id', endGameId)
            .maybeSingle();
            
        if (assignment != null && assignment['completed_at'] != null) {
          endGameComplete = true;
        }
      }
      
      if (!endGameComplete) {
        debugPrint('Level $currentLevel End Game NOT complete.');
        return false;
      }
      
      // 4. Promote!
      final nextLevel = currentLevel + 1;
      await _supabase
          .from('usr_dept')
          .update({'current_level': nextLevel})
          .eq('id', usrDept['id']);
          
      debugPrint('🎉 PROMOTED User from Level $currentLevel to $nextLevel!');
      return true;

    } catch (e) {
      debugPrint('Error attempting level promotion: $e');
      return false;
    }
  }
}
