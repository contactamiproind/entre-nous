import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/game_types.dart';

/// Shared quiz API service for loading questions, saving progress, and submitting quizzes.
/// Reusable across all question types.
class QuizService {
  final _supabase = Supabase.instance.client;

  // Cached values
  String? _usrDeptId;
  String? _deptId;

  /// Load global quiz settings (timer, thresholds) from SYSTEM_CONFIG.
  Future<QuizSettings> loadSettings() async {
    try {
      final res = await _supabase
          .from('departments')
          .select('levels')
          .eq('title', 'SYSTEM_CONFIG')
          .limit(1)
          .maybeSingle();

      if (res != null && res['levels'] != null) {
        final levelsList = res['levels'] as List;
        if (levelsList.isNotEmpty) {
          final s = levelsList[0];
          return QuizSettings(
            timerSeconds: _parseInt(s['timer_seconds'], 30),
            fullPointsThreshold: _parseDouble(s['full_points_threshold'], 0.5),
            halfPointsThreshold: _parseDouble(s['half_points_threshold'], 0.75),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading quiz settings: $e');
    }
    return const QuizSettings(); // defaults
  }

  /// Load questions for a category from usr_progress joined with questions table.
  /// Returns a list of processed question maps ready for the quiz screen.
  Future<QuizLoadResult> loadQuestions({
    required String category,
    String? subcategory,
    int? levelNumber,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Get department ID
    final deptData = await _supabase
        .from('departments')
        .select('id')
        .eq('category', category)
        .maybeSingle();

    if (deptData == null) {
      debugPrint('❌ No department found for category: $category');
      return QuizLoadResult(questions: [], deptId: null, usrDeptId: null);
    }

    final deptId = deptData['id'] as String;
    _deptId = deptId;

    // Get usr_dept record
    final usrDeptData = await _supabase
        .from('usr_dept')
        .select('id')
        .eq('user_id', user.id)
        .eq('dept_id', deptId)
        .maybeSingle();

    if (usrDeptData == null) {
      debugPrint('❌ No usr_dept found — admin must assign this department first');
      return QuizLoadResult(questions: [], deptId: deptId, usrDeptId: null);
    }

    final usrDeptId = usrDeptData['id'] as String;
    _usrDeptId = usrDeptId;

    // Load from usr_progress joined with questions
    var query = _supabase
        .from('usr_progress')
        .select('question_id, status, level_number, questions(id, title, description, options, correct_answer, type_id, level, points, dept_id)')
        .eq('usr_dept_id', usrDeptId);

    if (levelNumber != null) {
      query = query.eq('level_number', levelNumber);
    }

    final progressRecords = await query.order('created_at', ascending: true);
    debugPrint('📊 Found ${progressRecords.length} assigned questions');

    // Order: answered first, then unanswered
    final answered = <dynamic>[];
    final unanswered = <dynamic>[];
    for (final record in progressRecords) {
      final qd = record['questions'];
      if (qd == null) continue;
      if (record['status'] == 'answered') {
        answered.add(qd);
      } else {
        unanswered.add(qd);
      }
    }

    final rawList = [...answered, ...unanswered];
    debugPrint('📋 Ordered: ${answered.length} answered | ${unanswered.length} unanswered');

    // Process each question
    final questions = <Map<String, dynamic>>[];
    for (final qd in rawList) {
      questions.add(_processQuestion(qd));
    }

    return QuizLoadResult(
      questions: questions,
      deptId: deptId,
      usrDeptId: usrDeptId,
    );
  }

  /// Process a raw question record into a normalized map for the quiz screen.
  Map<String, dynamic> _processQuestion(Map<String, dynamic> qd) {
    final title = qd['title']?.toString() ?? '';
    final optionsRaw = qd['options'];

    // Detect type via structure first, then title fallback
    final inferredType = GameTypeDetector.detect(optionsRaw, title);
    debugPrint('   Type: $inferredType (title: $title)');

    // Parse MCQ options (only for MCQ-style types)
    List<String> options = [];
    List<Map<String, dynamic>> optionsData = [];

    if (!GameType.preservesRawOptions(inferredType) && optionsRaw != null) {
      final correctAnswer = qd['correct_answer']?.toString();
      if (optionsRaw is List) {
        for (var opt in optionsRaw) {
          if (opt is Map && opt['text'] != null) {
            final text = opt['text'].toString();
            options.add(text);
            optionsData.add({'text': text, 'is_correct': opt['is_correct'] ?? false});
          } else if (opt is String) {
            options.add(opt);
            optionsData.add({'text': opt, 'is_correct': opt == correctAnswer});
          }
        }
      }
    }

    return {
      'id': qd['id'],
      'title': qd['title'],
      'description': qd['description'],
      'level': qd['level'],
      'points': qd['points'] ?? 10,
      'options': GameType.preservesRawOptions(inferredType) ? optionsRaw : options,
      'options_data': optionsData,
      'correct_answer': qd['correct_answer'],
      'question_type': inferredType,
      'card_pairs': optionsRaw, // For card match
      'match_pairs': inferredType == GameType.matchFollowing ? optionsRaw : null,
    };
  }

  /// Save progress for a single question.
  Future<void> saveQuestionProgress({
    required String category,
    String? subcategory,
    required Map<String, dynamic> question,
    required bool isCorrect,
    required Map<String, dynamic> userAnswer,
    required int pointsEarned,
    required int attemptCount,
    String status = 'answered',
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final usrDeptId = await _getUsrDeptId(category);
      if (usrDeptId == null) {
        debugPrint('⚠️ Cannot save progress: usr_dept not found');
        return;
      }

      final deptId = await _getDeptId(category);
      if (deptId == null) return;

      final progressData = {
        'user_id': user.id,
        'dept_id': deptId,
        'usr_dept_id': usrDeptId,
        'question_id': question['id'],
        'question_text': question['title'],
        'question_type': question['question_type'],
        'category': category,
        'subcategory': subcategory,
        'points': question['points'] ?? 10,
        'status': status,
        'user_answer': userAnswer.toString(),
        'is_correct': isCorrect,
        'score_earned': pointsEarned,
        'attempt_count': attemptCount,
        'completed_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('usr_progress')
          .upsert(progressData, onConflict: 'usr_dept_id,question_id');

      debugPrint('💾 Saved: Q${question['id']} ${isCorrect ? "✅" : "❌"} ($pointsEarned pts)');
    } catch (e) {
      debugPrint('❌ Error saving question progress: $e');
    }
  }

  /// Load attempt count for a specific question.
  Future<AttemptInfo> loadAttemptInfo(String questionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return const AttemptInfo();

      final usrDeptId = _usrDeptId;
      if (usrDeptId == null) return const AttemptInfo();

      final data = await _supabase
          .from('usr_progress')
          .select('attempt_count, status')
          .eq('usr_dept_id', usrDeptId)
          .eq('question_id', questionId)
          .maybeSingle();

      if (data != null) {
        final status = data['status']?.toString() ?? 'pending';
        final saved = data['attempt_count'] as int? ?? 0;
        return AttemptInfo(status: status, attemptCount: saved);
      }
    } catch (e) {
      debugPrint('Error loading attempt: $e');
    }
    return const AttemptInfo();
  }

  // --- Private helpers ---

  Future<String?> _getUsrDeptId(String category) async {
    if (_usrDeptId != null) return _usrDeptId;
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final deptId = await _getDeptId(category);
    if (deptId == null) return null;

    final res = await _supabase
        .from('usr_dept')
        .select('id')
        .eq('user_id', user.id)
        .eq('dept_id', deptId)
        .maybeSingle();

    _usrDeptId = res?['id'];
    return _usrDeptId;
  }

  Future<String?> _getDeptId(String category) async {
    if (_deptId != null) return _deptId;
    final res = await _supabase
        .from('departments')
        .select('id')
        .eq('category', category)
        .maybeSingle();
    _deptId = res?['id'];
    return _deptId;
  }

  static int _parseInt(dynamic val, int fallback) {
    if (val == null) return fallback;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? fallback;
  }

  static double _parseDouble(dynamic val, double fallback) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }
}

/// Quiz settings loaded from SYSTEM_CONFIG.
class QuizSettings {
  final int timerSeconds;
  final double fullPointsThreshold;
  final double halfPointsThreshold;

  const QuizSettings({
    this.timerSeconds = 30,
    this.fullPointsThreshold = 0.5,
    this.halfPointsThreshold = 0.75,
  });
}

/// Result of loading questions.
class QuizLoadResult {
  final List<Map<String, dynamic>> questions;
  final String? deptId;
  final String? usrDeptId;

  const QuizLoadResult({
    required this.questions,
    this.deptId,
    this.usrDeptId,
  });
}

/// Info about a question's attempt history.
class AttemptInfo {
  final String status;
  final int attemptCount;

  const AttemptInfo({this.status = 'pending', this.attemptCount = 0});
}
