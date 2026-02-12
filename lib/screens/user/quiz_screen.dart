import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/progress_service.dart';
import '../../services/pathway_service.dart';
import '../../widgets/celebration_widget.dart';
import '../../widgets/card_match_question_widget.dart';
import '../../widgets/card_flip_game_widget.dart';
import '../../widgets/sequence_builder_widget.dart';
import '../../widgets/budget_allocation_widget.dart';
import 'package:audioplayers/audioplayers.dart';

class QuizScreen extends StatefulWidget {
  final String category; // 'Orientation', 'Process', or 'SOP'
  final String? subcategory; // Only for Orientation: 'Values', 'Goals', 'Vision', 'Greetings'
  final int? startQuestionIndex; // Optional: Start from specific question (for Continue feature)

  const QuizScreen({
    super.key,
    required this.category,
    this.subcategory,
    this.startQuestionIndex,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ProgressService _progressService = ProgressService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _score = 0;
  Map<int, int> _selectedAnswers = {}; // question_index -> answer_index
  bool _showResults = false;
  bool _showCelebration = false;
  int? _firstWrongQuestionIndex; // Track first wrong answer for Try Again
  Map<int, bool> _answeredCorrectly = {}; // Track which questions were answered correctly
  
  Map<int, Map<String, String?>> _matchAnswers = {}; // question_index -> {left_item -> selected_right_item}
  Map<int, int> _gameScores = {}; // question_index -> score (for interactive games)
  Map<int, int> _questionPoints = {}; // question_index -> points earned (time-based)
  Map<int, int> _questionAnswerTimes = {}; // question_index -> remaining seconds when answered
  
  // Timer variables
  Timer? _questionTimer;
  int _remainingSeconds = 30;
  int _questionTimeLimit = 30; // Default 30, loaded from DB
  int _questionStartTime = 30; // Track time when question started
  
  // Scoring thresholds
  double _fullPointsThreshold = 0.5;
  double _halfPointsThreshold = 0.75;
  
  // Attempt tracking
  int _currentAttempt = 1;
  static const int _maxAttempts = 2;
  
  // Progress tracking
  String? _usrDeptId; // ID of the usr_dept record for saving progress
  
  // Card game tracking
  // State variables for Question Type specific logic
  final Map<int, Set<String>> _droppedItems = {};
  bool _isCardGameComplete = false;
  
  // Department ID to track progress
  String? _deptId;
  
  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    setState(() {
      _remainingSeconds = _questionTimeLimit;
      _questionStartTime = _questionTimeLimit; // Record start time
    });
    
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        
        // Haptic feedback when reaching 10 seconds
        if (_remainingSeconds == 10) {
          HapticFeedback.mediumImpact();
        }
      } else {
        timer.cancel();
        _handleTimeExpired();
      }
    });
  }

  void _handleTimeExpired() {
    // Show retry dialog when time expires
    _questionTimer?.cancel();
    
    if (_currentAttempt < _maxAttempts) {
      _showRetryDialog();
    } else {
      // After max attempts, show message and allow answering with 0 points
      _showNoPointsDialog();
    }
  }
  
  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.timer_off, color: Color(0xFFF08A7E), size: 28),
            SizedBox(width: 12),
            Text('Time\'s Up!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve used all 30 seconds for this question.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Attempt $_currentAttempt of $_maxAttempts',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _retryQuestion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  void _showNoPointsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Color(0xFFF08A7E), size: 28),
            SizedBox(width: 12),
            Text('No Points Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'You\'ve used both attempts for this question.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'You can still answer, but you won\'t earn any points.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF08A7E),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  void _retryQuestion() {
    setState(() {
      _currentAttempt++;
      // Clear the previous wrong answer so user can select again
      _selectedAnswers.remove(_currentQuestionIndex);
    });
    // Reset timer to 30 seconds and restart
    _startQuestionTimer();
  }

  int _calculatePoints(int questionIndex) {
    if (questionIndex >= 0 && questionIndex < _questions.length) {
      return (_questions[questionIndex]['points'] as int?) ?? 10;
    }
    return 10; // Default fallback
  }

  void _recordAnswerWithPoints(bool isCorrect, int questionIndex) {
    // Record points for the specified question
    
    // If user has exceeded max attempts, award 0 points regardless of correctness
    if (_currentAttempt > _maxAttempts) {
      _questionPoints[questionIndex] = 0;
      debugPrint('⚠️ Question $questionIndex: 0 points (exceeded max attempts)');
      return;
    }
    
    if (isCorrect) {
      final points = _calculatePoints(questionIndex);
      _questionPoints[questionIndex] = points;
      debugPrint('✅ Question $questionIndex: Earned $points points');
    } else {
      _questionPoints[questionIndex] = 0;
      debugPrint('❌ Question $questionIndex: 0 points (incorrect answer)');
    }
  }

  void _recordAnswerTime() {
    // Record the remaining time when the current question is answered
    _questionAnswerTimes[_currentQuestionIndex] = _remainingSeconds;
    debugPrint('⏱️ Question $_currentQuestionIndex answered with $_remainingSeconds seconds remaining');
  }
  
  /// Get usr_dept record for the current category (admin must have created it)
  Future<String?> _getUsrDept() async {
    if (_usrDeptId != null) return _usrDeptId;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      
      // Get department ID for this category
      final deptData = await Supabase.instance.client
          .from('departments')
          .select('id')
          .eq('category', widget.category)
          .maybeSingle();
      
      if (deptData == null) {
        debugPrint('❌ Department not found for category: ${widget.category}');
        return null;
      }
      
      final deptId = deptData['id'];
      
      // Only look up existing usr_dept — never create (admin assigns these)
      final existingUsrDept = await Supabase.instance.client
          .from('usr_dept')
          .select('id')
          .eq('user_id', user.id)
          .eq('dept_id', deptId)
          .maybeSingle();
      
      if (existingUsrDept != null) {
        _usrDeptId = existingUsrDept['id'];
        debugPrint('✅ Found usr_dept: $_usrDeptId');
        return _usrDeptId;
      }
      
      debugPrint('❌ No usr_dept found — admin must assign this department first');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting usr_dept: $e');
      return null;
    }
  }
  
  /// Save progress for a single question to the database
  Future<void> _saveQuestionProgress({
    required int questionIndex,
    required Map<String, dynamic> question,
    required bool isCorrect,
    required Map<String, dynamic> userAnswer,
    required int pointsEarned,
    String status = 'answered',
  }) async {
    try {
      // Get or create usr_dept record
      final usrDeptId = await _getUsrDept();
      if (usrDeptId == null) {
        debugPrint('⚠️ Cannot save progress: usr_dept not found');
        return;
      }
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      // Get department ID
      final deptData = await Supabase.instance.client
          .from('departments')
          .select('id')
          .eq('category', widget.category)
          .maybeSingle();
      
      if (deptData == null) return;
      final deptId = deptData['id'];
      
      final questionId = question['id'];
      
      // Prepare progress data
    final progressData = {
      'user_id': user.id,
      'dept_id': deptId,
      'usr_dept_id': usrDeptId,
      'question_id': questionId,
      'question_text': question['title'],
      'question_type': question['question_type'],
      'category': widget.category,
      'subcategory': widget.subcategory,
      'points': question['points'] ?? 10,
      'status': status,
      'user_answer': userAnswer.toString(),
      'is_correct': isCorrect,
      'score_earned': pointsEarned,
      'attempt_count': _currentAttempt,
      'completed_at': DateTime.now().toIso8601String(),
    };
      
      // Upsert to handle both new answers and retries
      await Supabase.instance.client
          .from('usr_progress')
          .upsert(progressData, onConflict: 'usr_dept_id,question_id');
      
      debugPrint('💾 Saved progress for question $questionIndex: ${isCorrect ? "✅ Correct" : "❌ Wrong"} ($pointsEarned points)');
    } catch (e) {
      debugPrint('❌ Error saving question progress: $e');
    }
  }

  // Load the attempt count for the current question from DB
  Future<void> _loadCurrentQuestionAttempt() async {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) return;
    
    try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return;
        
        final questionId = _questions[_currentQuestionIndex]['id'];
        final usrDeptId = await _getUsrDept();
        
        if (usrDeptId == null) return;
        
        final data = await Supabase.instance.client
            .from('usr_progress')
            .select('attempt_count, status')
            .eq('usr_dept_id', usrDeptId)
            .eq('question_id', questionId)
            .maybeSingle();
            
        if (data != null) {
          int savedAttempts = data['attempt_count'] ?? 1;
          debugPrint('🔄 Loaded attempt count for Q$questionId: $savedAttempts (Status: ${data['status']})');
          
          if (mounted) {
            setState(() {
              // If we loaded a valid attempt count, use it.
              // If the status is 'pending', it means we are in the middle of that attempt? 
              // Or does 'attempt_count' store the COMPLETED attempts?
              // Let's assume attempt_count stores "attempts MADE/USED".
              // So if DB says 1, we are starting attempt 2.
              _currentAttempt = savedAttempts + 1;
            });
          }
        } else {
           debugPrint('🆕 No previous progress for Q$questionId. Starting Attempt 1.');
           if (mounted) setState(() => _currentAttempt = 1);
        }
    } catch (e) {
      debugPrint('Error loading attempt count: $e');
    }
  }

  Future<void> _loadQuestions() async {
    try {
      
      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      // Load global quiz settings
      try {
        debugPrint('🔍 Fetching SYSTEM_CONFIG...');
        final settingsResponse = await Supabase.instance.client
            .from('departments')
            .select('levels')
            .eq('title', 'SYSTEM_CONFIG')
            .limit(1)
            .maybeSingle();
            
        debugPrint('📦 Settings Response: $settingsResponse');

        if (settingsResponse != null && settingsResponse['levels'] != null) {
          final levelsList = settingsResponse['levels'] as List;
          if (levelsList.isNotEmpty) {
            final settings = levelsList[0];
            debugPrint('⚙️ Parsed Settings: $settings');
            
            if (mounted) {
              setState(() {
                if (settings['timer_seconds'] != null) {
                  // Robust parsing: handle String or Int
                  final val = settings['timer_seconds'];
                  final parsed = val is int ? val : int.tryParse(val.toString()) ?? 30;
                  
                  _questionTimeLimit = parsed;
                  _remainingSeconds = _questionTimeLimit;
                  _questionStartTime = _questionTimeLimit;
                  debugPrint('⏱️ SET Timer to: $_questionTimeLimit seconds');
                }
                
                if (settings['full_points_threshold'] != null) {
                   final val = settings['full_points_threshold'];
                   _fullPointsThreshold = (val is num ? val : double.tryParse(val.toString()) ?? 0.5).toDouble();
                }
                
                if (settings['half_points_threshold'] != null) {
                   final val = settings['half_points_threshold'];
                   _halfPointsThreshold = (val is num ? val : double.tryParse(val.toString()) ?? 0.75).toDouble();
                }
              });
              
            }
          } else {
             debugPrint('⚠️ SYSTEM_CONFIG levels list is empty');
          }
        } else {
           debugPrint('⚠️ SYSTEM_CONFIG not found or levels null');
        }
      } catch (e) {
        debugPrint('❌ Error loading settings (using defaults): $e');
      }

      
      debugPrint('🔍 Loading questions for category: ${widget.category}');
      
      // First, get the department ID for this category
      final departmentData = await Supabase.instance.client
          .from('departments')
          .select('id')
          .eq('category', widget.category)
          .maybeSingle();
      
      if (departmentData == null) {
        debugPrint('❌ No department found for category: ${widget.category}');
        setState(() => _isLoading = false);
        return;
      }
      
      final deptId = departmentData['id'];
      _deptId = deptId;
      debugPrint('📁 Found department ID: $deptId');
      
      // Get usr_dept record (admin must have created it)
      final usrDeptData = await Supabase.instance.client
          .from('usr_dept')
          .select('id')
          .eq('user_id', user.id)
          .eq('dept_id', deptId)
          .maybeSingle();
      
      if (usrDeptData == null) {
        debugPrint('❌ No usr_dept found — admin must assign this department first');
        setState(() => _isLoading = false);
        return;
      }
      
      final usrDeptId = usrDeptData['id'];
      _usrDeptId = usrDeptId;
      debugPrint('✅ Found usr_dept: $usrDeptId');
      
      // Load questions ONLY from usr_progress (admin-assigned questions)
      // Join with questions table to get full question data
      final progressRecords = await Supabase.instance.client
          .from('usr_progress')
          .select('question_id, status, questions(id, title, description, options, correct_answer, type_id, level, points, dept_id)')
          .eq('usr_dept_id', usrDeptId)
          .order('created_at', ascending: true);
      
      debugPrint('📊 Found ${progressRecords.length} assigned questions from usr_progress');
      
      // Order: answered first, then unanswered (for resume feature)
      final List<dynamic> answeredList = [];
      final List<dynamic> unansweredList = [];
      
      for (final record in progressRecords) {
        final questionData = record['questions'];
        if (questionData == null) continue;
        if (record['status'] == 'answered') {
          answeredList.add(questionData);
        } else {
          unansweredList.add(questionData);
        }
      }
      
      final List<dynamic> questionsList = [...answeredList, ...unansweredList];
      debugPrint('📋 Ordered: ${answeredList.length} answered | ${unansweredList.length} unanswered');

      List<Map<String, dynamic>> questions = [];
      
      // Process each question from the database
      for (var questionData in questionsList) {
        
        // Infer question type from title AND options structure
        String inferredType = 'multiple_choice'; // Default type
        final title = questionData['title']?.toString().toLowerCase() ?? '';
        final optionsRaw = questionData['options'];
        
        // Check if options structure indicates card match (Map with cards/buckets)
        bool isCardMatchByStructure = false;
        if (optionsRaw is Map) {
          final hasCards = optionsRaw.containsKey('cards');
          final hasBuckets = optionsRaw.containsKey('buckets');
          isCardMatchByStructure = hasCards && hasBuckets;
        }
        
        if (isCardMatchByStructure) {
          // Detected as card match by structure - most reliable
          inferredType = 'card_match';
          debugPrint('   ✅ Card Match detected by OPTIONS STRUCTURE');
        } else if (title.contains('single tap')) {
          inferredType = 'single_tap_choice';
        } else if (title.contains('card match') || title.contains('card_match')) {
          inferredType = 'card_match';
          debugPrint('   ✅ Card Match detected by TITLE');
        } else if (title.contains('scenario') || title.contains('decision')) {
          inferredType = 'scenario_decision';
        } else if (title.contains('sequence') || title.contains('arrange') || title.contains('order')) {
          inferredType = 'sequence_builder';
          debugPrint('   ✅ Sequence Builder detected by TITLE');
        } else if (title.contains('simulation') || title.contains('budget')) {
          inferredType = 'simulation';
          debugPrint('   ✅ Budget Simulation detected by TITLE');
        } else if (title.contains('match')) {
          // Only set to match_following if it's not already identified as card_match
          inferredType = 'match_following';
        }
        
        debugPrint('   Question type inferred: $inferredType (title: $title)');
        
        
        // Extract options from the question data
      List<String> options = [];
      List<Map<String, dynamic>> optionsData = [];
      
      // Skip options processing for card_match, sequence_builder, and simulation questions - they use different structures
      if (inferredType != 'card_match' && inferredType != 'sequence_builder' && inferredType != 'simulation' && questionData['options'] != null) {
        final optionsRaw = questionData['options'];
        final correctAnswer = questionData['correct_answer']?.toString();
        
        // Handle both List and Map formats
        if (optionsRaw is List) {
          // Array format: [{text: "...", is_correct: true}, ...]
          for (var opt in optionsRaw) {
            if (opt is Map && opt['text'] != null) {
              // New format: {text: "...", is_correct: true/false}
              final optionText = opt['text'].toString();
              options.add(optionText);
              optionsData.add({
                'text': optionText,
                'is_correct': opt['is_correct'] ?? false,
              });
            } else if (opt is String) {
              // Old format: ["option1", "option2", ...]
              // Use correct_answer field to determine which is correct
              options.add(opt);
              optionsData.add({
                'text': opt,
                'is_correct': opt == correctAnswer,
              });
            }
          }
        } else if (optionsRaw is Map) {
          // Object format: {cards: [...]} for card_match questions
          // Just store it as-is for card match questions
          debugPrint('   Options is a Map (likely card_match question)');
        }
        
        debugPrint('  Question ${questionData['id']}: loaded ${options.length} options');
      } else if (inferredType == 'card_match') {
        debugPrint('  Card Match question - preserving Map structure');
      } else if (inferredType == 'sequence_builder') {
        debugPrint('  Sequence Builder question - preserving List structure');
      }  
        
        questions.add({
          'id': questionData['id'],
          'title': questionData['title'],
          'description': questionData['description'],
          'level': questionData['level'],
          'points': questionData['points'] ?? 10,
          'options': (inferredType == 'card_match' || inferredType == 'sequence_builder' || inferredType == 'simulation') ? questionData['options'] : options, // Keep original structure for card_match, sequence_builder, and simulation
          'options_data': optionsData, // Store full option data with is_correct flags
          'correct_answer': questionData['correct_answer'], // CRITICAL: Add for validation
          'question_type': inferredType, // Use inferred type
          'card_pairs': questionData['options'], // For Card Match questions
        });
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
        _matchAnswers = {};
        _gameScores = {};
        
        // Set initial question index (for Continue feature)
        if (widget.startQuestionIndex != null && widget.startQuestionIndex! < questions.length) {
          _currentQuestionIndex = widget.startQuestionIndex!;
        }
      });
      
      // Start timer for current question (may not be first if resuming)
      if (questions.isNotEmpty) {
        _loadCurrentQuestionAttempt().then((_) => _startQuestionTimer());
      }
    } catch (e) {
      debugPrint('❌ Error loading questions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitQuiz() async {
    debugPrint('📊 === SUBMITTING QUIZ ===');
    debugPrint('Total questions: ${_questions.length}');
    debugPrint('Game scores map: $_gameScores');

    // Record answer time for current question before processing
    _recordAnswerTime();

    int correctCount = 0;
    int totalScore = 0;
    final int questionValue = 100; // Customizable per question logic if needed

    // 1. Calculate Score first
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final questionType = question['question_type'] ?? 'multiple_choice';
      debugPrint('Question $i: Type = $questionType');
      
      bool isCorrect = false;
      
      if (questionType == 'multiple_choice' || questionType == 'single_tap_choice' || questionType == 'scenario_decision') {
        final selectedIndex = _selectedAnswers[i];
        final options = List<String>.from(question['options'] ?? []);
        
        // Get options_data which contains is_correct flags
        final optionsDataRaw = question['options_data'];
        List<Map<String, dynamic>> optionsData = [];
        if (optionsDataRaw is List) {
          optionsData = optionsDataRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        
        debugPrint('📝 Question $i: ${options.length} options');
        debugPrint('   Selected index: $selectedIndex');
        debugPrint('   Options data: $optionsData');
        
        if (selectedIndex != null && selectedIndex < options.length && selectedIndex < optionsData.length) {
          final selectedAnswerText = options[selectedIndex];
          final isCorrectOption = optionsData[selectedIndex]['is_correct'] == true;
          
          debugPrint('Checking Answer: "$selectedAnswerText" (Index: $selectedIndex)');
          debugPrint('   is_correct flag: $isCorrectOption');
          
          if (isCorrectOption) {
            debugPrint('✅ Answer Correct!');
            isCorrect = true;
          } else {
            debugPrint('❌ Answer Wrong');
          }
        }
      } else if (questionType == 'match_following') {
        // ... (Match logic is unchanged, assuming it works or isn't used here)
        final pairs = List<Map<String, dynamic>>.from(question['match_pairs'] ?? []);
        final userMatches = _matchAnswers[i] ?? {};
        
        bool allCorrect = true;
        for (var pair in pairs) {
          final left = pair['left'] as String;
          final correctRight = pair['right'] as String;
          final selectedRight = userMatches[left];
          final selectedValue = selectedRight?.split('|')[0]; // Value before pipe
          
          if (selectedValue != correctRight) {
            allCorrect = false;
            break;
          }
        }
        
        if (allCorrect && userMatches.length == pairs.length) {
          isCorrect = true;
        }
      }

      // Track if this question was answered correctly
      _answeredCorrectly[i] = isCorrect;
      
      // Track first wrong answer for Try Again functionality
      if (!isCorrect && _firstWrongQuestionIndex == null) {
        _firstWrongQuestionIndex = i;
      }
      
      if (questionType == 'card_match' || questionType == 'sequence_builder' || questionType == 'simulation') {
        final score = _gameScores[i] ?? 0;
        debugPrint('🎮 $questionType Question $i: Score = $score');
        totalScore += score;
        // Count as correct if score is 25 or higher (out of max ~60)
        if (score >= 25) {
          debugPrint('✅ $questionType counted as CORRECT (score >= 25)');
          correctCount++;
          _answeredCorrectly[i] = true;
        } else {
          debugPrint('❌ $questionType counted as WRONG (score < 25)');
        }
      } else {
        if (isCorrect) {
          correctCount++;
          totalScore += questionValue;
          debugPrint('🔵 About to record points for question $i (correct)');
          // Record time-based points for correct answer
          _recordAnswerWithPoints(true, i);
        } else {
          debugPrint('🔵 About to record points for question $i (incorrect)');
          // Record 0 points for incorrect answer
          _recordAnswerWithPoints(false, i);
        }
      }
    }

    // 2. Show Results & Celebration IMMEDIATELY
    final percentage = _questions.isEmpty ? 0.0 : (correctCount / _questions.length) * 100;
    debugPrint('Quiz completed! Score: $percentage%');
    
    setState(() {
      _score = totalScore;
      _showResults = true;
      
      if (percentage >= 70) {
        debugPrint('🎉 Triggering celebration!');
        _showCelebration = true;
        
        // Play success sound
        try {
          _audioPlayer.setVolume(1.0);
          _audioPlayer.play(AssetSource('sounds/success.mp3'));
          debugPrint('Playing success sound');
        } catch (e) {
          debugPrint('Could not play sound: $e');
        }
        HapticFeedback.mediumImpact();
      }
    });

    // 3. Save to Database (Async, don't block UI)
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // ⚠️ IMPORTANT: Questions are already saved when answered via _saveQuestionProgress
        // We do NOT re-save them here to avoid overwriting correct data
        // The save happens in real-time when:
        // - Single/multiple choice: when user taps "Next" after selecting answer
        // - Game types: when game completes successfully
        
        // for (int i = 0; i < _questions.length; i++) {
        //    ... REMOVED: Duplicate save logic that was overwriting correct progress ...
        // }



        if (widget.category.toLowerCase() == 'orientation') {
          await PathwayService().markOrientationComplete(user!.id);
        }

        // Auto-unlock next category if user passed (>= 70%)
        if (percentage >= 70) {
          try {
            // TODO: Implement category unlocking logic
            // - If all Orientation subcategories completed, unlock Process
            // - If Process completed, unlock SOP
            debugPrint('🔓 Category completion check needed');
          } catch (e) {
            debugPrint('Error unlocking next category: $e');
          }
        }
        
        // --- ATTEMPT LEVEL PROMOTION ---
        // If this quiz completed the level requirements, promote user!
        if (_deptId != null) {
           debugPrint('🔍 Attempting level promotion check for dept $_deptId...');
           // We need to use ProgressService instance or create one
           final progressService = ProgressService(); // Or inject/locate it
           await progressService.attemptLevelPromotion(user.id, _deptId!);
        }
        // -------------------------------
        }
      } catch (e) {
      debugPrint('❌ Error saving final progress / promoting: $e');
      // Do not show error to user, they have their results
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.subcategory != null 
              ? '${widget.category} - ${widget.subcategory}'
              : widget.category),
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF9E6), // Very light yellow
                Color(0xFFF4EF8B), // Main yellow #f4ef8b
                Color(0xFFE8D96F), // Darker yellow
              ],
            ),
          ),
          child: const Center(
            child: Text(
              'No questions available for this category yet.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    if (_showResults) {
      return _buildResultsScreen();
    }

    final question = _questions[_currentQuestionIndex];
    final questionType = question['question_type'] ?? 'multiple_choice';
    debugPrint('🔍 QUESTION TYPE = "$questionType"');
    debugPrint('   Question data: ${question.keys.toList()}');
    
    // Determine if current question is answered
    // A question is considered answered if:
    // 1. It's been marked in _answeredCorrectly (correct answer OR wrong after max attempts)
    // 2. OR for match questions, all pairs have been matched
    bool isAnswered = false;
    if (_answeredCorrectly.containsKey(_currentQuestionIndex)) {
      // Question has been fully processed (correct or wrong after attempts)
      isAnswered = true;
      debugPrint('🔵 Question $_currentQuestionIndex is ANSWERED (in _answeredCorrectly map)');
    } else if (questionType == 'multiple_choice' || questionType == 'single_tap_choice' || questionType == 'scenario_decision') {
      // For multiple choice, check if an answer is selected (but not yet validated)
      isAnswered = _selectedAnswers[_currentQuestionIndex] != null;
      debugPrint('🔵 Question $_currentQuestionIndex isAnswered = $isAnswered (selected: ${_selectedAnswers[_currentQuestionIndex]})');
    } else if (questionType == 'match_following') {
      final pairs = List<Map<String, dynamic>>.from(question['match_pairs'] ?? []);
      final userMatches = _matchAnswers[_currentQuestionIndex] ?? {};
      isAnswered = userMatches.length == pairs.length;
      debugPrint('🔵 Question $_currentQuestionIndex isAnswered = $isAnswered (matches: ${userMatches.length}/${pairs.length})');
    } else if (questionType == 'card_match' || questionType == 'sequence_builder') {
      // For card match and sequence builder, check if game is complete
      isAnswered = _isCardGameComplete;
      debugPrint('🔵 Question $_currentQuestionIndex isAnswered = $isAnswered (game complete: $_isCardGameComplete)');
    }
    
    debugPrint('🔵 _answeredCorrectly map: $_answeredCorrectly');
    debugPrint('🔵 _selectedAnswers map: $_selectedAnswers');
    debugPrint('🔵 Current attempt: $_currentAttempt / $_maxAttempts');


    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9E6), // Very light yellow
              Color(0xFFF4EF8B), // Main yellow #f4ef8b
              Color(0xFFE8D96F), // Darker yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      widget.subcategory != null 
                          ? '${widget.category} - ${widget.subcategory}'
                          : widget.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    // Small Progress Bar
                    Container(
                      width: 80, 
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_currentQuestionIndex + 1) / _questions.length,
                          color: const Color(0xFFFBBF24), // Yellow
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Bar moved to header
                      
                      // Question Counter and Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Timer Display - Enhanced visibility
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            transform: _remainingSeconds <= 10 
                                ? (Matrix4.identity()..scale(1.1))
                                : Matrix4.identity(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _remainingSeconds <= 10 
                                  ? Colors.red
                                  : const Color(0xFFFBBF24),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _remainingSeconds <= 10
                                      ? Colors.red.withOpacity(0.5)
                                      : const Color(0xFFFBBF24).withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _remainingSeconds <= 10 
                                      ? Icons.warning_amber_rounded
                                      : Icons.timer,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_remainingSeconds',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: _remainingSeconds <= 10 ? 28 : 24,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  's',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: _remainingSeconds <= 10 ? 18 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Question Text or Type Indicator
                      if (questionType == 'match_following')
                        Text(
                          'Match the Following items below!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: const Color(0xFF1A2F4B),
                          ),
                        )
                      else
                        Text(
                          question['title'] ?? question['question_text'] ?? 'Question',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.black,
                            fontSize: 22,
                            height: 1.3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (question['description'] != null && question['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            question['description'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.4,
                            ),
                          ),
                        ],
                      const SizedBox(height: 6),
                      
                      // Question Content (Scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          child: questionType == 'sequence_builder'
                                      ? SequenceBuilderWidget(
                                        key: ValueKey('seq_${question['id']}'),
                                        questionData: question,
                                        onAnswerSubmitted: (score, isCorrect) {
                                          setState(() {
                                            _isCardGameComplete = true;
                                            _gameScores[_currentQuestionIndex] = score;
                                            _answeredCorrectly[_currentQuestionIndex] = isCorrect;
                                          });
                                        },
                                      )
                                  : questionType == 'card_match'
                                  ? _isFlipCardGame(question)
                                      ? SizedBox(
                                          height: 700,
                                          child: CardFlipGameWidget(
                                            key: ValueKey('flip_${question['id']}'),
                                            pairs: _buildCardPairs(question),
                                            pointsPerMatch: 10,
                                            onGameComplete: (score, accuracy) {
                                              // Game is complete, store score and enable Next button
                                              setState(() {
                                                _isCardGameComplete = true;
                                                _gameScores[_currentQuestionIndex] = score;
                                                _answeredCorrectly[_currentQuestionIndex] = accuracy >= 0.7;
                                              });
                                            },
                                            onComplete: (score, accuracy, timeTaken) async {
                                              // This will be called when Next is clicked
                                              // Save progress
                                              await _saveQuestionProgress(
                                                questionIndex: _currentQuestionIndex,
                                                question: question,
                                                isCorrect: accuracy >= 0.7,
                                                userAnswer: {
                                                  'type': 'card_match_flip',
                                                  'score': score,
                                                  'accuracy': accuracy,
                                                  'time_taken': timeTaken,
                                                },
                                                pointsEarned: score,
                                              );
                                              
                                              setState(() {
                                                _answeredCorrectly[_currentQuestionIndex] = accuracy >= 0.7;
                                                _gameScores[_currentQuestionIndex] = score;
                                              });
                                              
                                              if (_currentQuestionIndex < _questions.length - 1) {
                                                setState(() {
                                                  _currentQuestionIndex++;
                                                  _currentAttempt = 1;
                                                  _isCardGameComplete = false; // Reset for next question
                                                });
                                                _startQuestionTimer();
                                              } else {
                                                _submitQuiz();
                                              }
                                            },
                                          ),
                                        )
                                        : SizedBox(
                                          height: 700,
                                          child: CardMatchQuestionWidget(
                                            questionData: () {
                                              debugPrint('🎮 Creating CardMatchQuestionWidget');
                                              debugPrint('   Question ID: ${question['id']}');
                                              debugPrint('   Options type: ${question['options'].runtimeType}');
                                              debugPrint('   Options value: ${question['options']}');
                                              return question;
                                            }(),
                                            onAnswerSubmitted: (score, isCorrect) async {
                                              // Stop timer
                                              _questionTimer?.cancel();
                                              
                                              // Save state
                                              setState(() {
                                                _isCardGameComplete = true;
                                                _gameScores[_currentQuestionIndex] = score;
                                                _answeredCorrectly[_currentQuestionIndex] = isCorrect;
                                              });

                                              // Show celebration
                                              await Future.delayed(const Duration(milliseconds: 300));
                                              if (mounted) {
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  barrierColor: Colors.black.withOpacity(0.7),
                                                  builder: (context) => CelebrationWidget(
                                                    show: true,
                                                    points: score,
                                                    onComplete: () async {
                                                      Navigator.of(context).pop();
                                                      
                                                      // Save progress explicitly
                                                      await _saveQuestionProgress(
                                                        questionIndex: _currentQuestionIndex,
                                                        question: question,
                                                        isCorrect: true, // Assuming completion = correct enough
                                                        userAnswer: {
                                                          'type': 'card_match',
                                                          'score': score,
                                                          'time_taken': _questionTimeLimit - _remainingSeconds,
                                                        },
                                                        pointsEarned: score,
                                                      );
                                                      
                                                      if (_currentQuestionIndex < _questions.length - 1) {
                                                        setState(() {
                                                          _currentQuestionIndex++;
                                                          _currentAttempt = 1;
                                                          _isCardGameComplete = false;
                                                          // Reset timer
                                                          _remainingSeconds = 30;
                                                        });
                                                        _loadCurrentQuestionAttempt().then((_) => _startQuestionTimer());
                                                      } else {
                                                        _submitQuiz();
                                                      }
                                                    },
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        )
                                  : questionType == 'simulation'
                                  ? SizedBox(
                                      height: 700,
                                      child: BudgetAllocationWidget(
                                        questionData: question,
                                        onAnswerSubmitted: (score, isCorrect) {
                                          setState(() {
                                            _isCardGameComplete = true;
                                            _gameScores[_currentQuestionIndex] = score;
                                            _answeredCorrectly[_currentQuestionIndex] = isCorrect;
                                          });
                                        },
                                      ),
                                    )
                                  : (questionType == 'multiple_choice' || questionType == 'single_tap_choice' || questionType == 'scenario_decision')
                                      ? _buildMultipleChoiceOptions(question)
                                      : _buildMatchTheFollowing(question),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Navigation Buttons with bottom padding to avoid bottom bar
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentQuestionIndex > 0)
                              OutlinedButton(
                                onPressed: () {
                                  setState(() => _currentQuestionIndex--);
                                  _startQuestionTimer(); // Restart timer for previous question
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                ),
                                child: const Text('Previous'),
                              )
                            else
                              const SizedBox(), // Spacer
                              
                            ElevatedButton(
                              onPressed: !isAnswered
                                  ? null
                                  : () async {
                                      final question = _questions[_currentQuestionIndex];
                                      final questionType = question['question_type'] ?? 'multiple_choice';
                                      
                                      // Handle card match games
                                      if (questionType == 'card_match' && _isCardGameComplete) {
                                        // Get the game score from the state
                                        final score = _gameScores[_currentQuestionIndex] ?? 0;
                                        final accuracy = score >= 25 ? 0.7 : 0.5; // Simple accuracy based on score
                                        
                                        // Stop timer
                                        _questionTimer?.cancel();
                                        
                                        // Show celebration with score
                                        await Future.delayed(const Duration(milliseconds: 300));
                                        if (mounted) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            barrierColor: Colors.black.withOpacity(0.7),
                                            builder: (context) => CelebrationWidget(
                                              show: true,
                                              points: score,
                                              onComplete: () async {
                                                Navigator.of(context).pop();
                                                
                                                // Now trigger the actual completion which saves and advances
                                                // This will call the onComplete callback we set up earlier
                                                // But we need to do it manually here
                                                await _saveQuestionProgress(
                                                  questionIndex: _currentQuestionIndex,
                                                  question: question,
                                                  isCorrect: accuracy >= 0.7,
                                                  userAnswer: {
                                                    'type': 'card_match_flip',
                                                    'score': score,
                                                    'accuracy': accuracy,
                                                    'time_taken': _questionTimeLimit - _remainingSeconds,
                                                  },
                                                  pointsEarned: score,
                                                );
                                                
                                                setState(() {
                                                  _answeredCorrectly[_currentQuestionIndex] = accuracy >= 0.7;
                                                  _gameScores[_currentQuestionIndex] = score;
                                                });
                                                
                                                // Move to next question
                                                if (_currentQuestionIndex < _questions.length - 1) {
                                                  setState(() {
                                                    _currentQuestionIndex++;
                                                    _currentAttempt = 1;
                                                    _isCardGameComplete = false; // Reset for next question
                                                  });
                                                  _loadCurrentQuestionAttempt().then((_) => _startQuestionTimer());
                                                } else {
                                                  _submitQuiz();
                                                }
                                              },
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      
                                      // Handle sequence builder games
                                      if (questionType == 'sequence_builder' && _isCardGameComplete) {
                                        // Get the game score from the state
                                        final score = _gameScores[_currentQuestionIndex] ?? 0;
                                        final isCorrect = _answeredCorrectly[_currentQuestionIndex] ?? false;
                                        
                                        // Stop timer
                                        _questionTimer?.cancel();
                                        
                                        // Show celebration with score
                                        await Future.delayed(const Duration(milliseconds: 300));
                                        if (mounted) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            barrierColor: Colors.black.withOpacity(0.7),
                                            builder: (context) => CelebrationWidget(
                                              show: true,
                                              points: score,
                                              onComplete: () async {
                                                Navigator.of(context).pop();
                                                
                                                // Save progress
                                                await _saveQuestionProgress(
                                                  questionIndex: _currentQuestionIndex,
                                                  question: question,
                                                  isCorrect: isCorrect,
                                                  userAnswer: {
                                                    'type': 'sequence_builder',
                                                    'score': score,
                                                    'time_taken': _questionTimeLimit - _remainingSeconds,
                                                  },
                                                  pointsEarned: score,
                                                );
                                                
                                                setState(() {
                                                  _answeredCorrectly[_currentQuestionIndex] = isCorrect;
                                                  _gameScores[_currentQuestionIndex] = score;
                                                });
                                                
                                                // Move to next question
                                                if (_currentQuestionIndex < _questions.length - 1) {
                                                  setState(() {
                                                    _currentQuestionIndex++;
                                                    _currentAttempt = 1;
                                                    _isCardGameComplete = false; // Reset for next question
                                                  });
                                                  _loadCurrentQuestionAttempt().then((_) => _startQuestionTimer());
                                                } else {
                                                  _submitQuiz();
                                                }
                                              },
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      
                                      // Handle simulation (budget allocation) games
                                      if (questionType == 'simulation' && _isCardGameComplete) {
                                        // Get the game score from the state
                                        final score = _gameScores[_currentQuestionIndex] ?? 0;
                                        final isCorrect = _answeredCorrectly[_currentQuestionIndex] ?? false;
                                        
                                        // Stop timer
                                        _questionTimer?.cancel();
                                        
                                        // Show celebration with score
                                        await Future.delayed(const Duration(milliseconds: 300));
                                        if (mounted) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            barrierColor: Colors.black.withOpacity(0.7),
                                            builder: (context) => CelebrationWidget(
                                              show: true,
                                              points: score,
                                              onComplete: () async {
                                                Navigator.of(context).pop();
                                                
                                                // Save progress
                                                await _saveQuestionProgress(
                                                  questionIndex: _currentQuestionIndex,
                                                  question: question,
                                                  isCorrect: isCorrect,
                                                  userAnswer: {
                                                    'type': 'simulation',
                                                    'score': score,
                                                    'time_taken': _questionTimeLimit - _remainingSeconds,
                                                  },
                                                  pointsEarned: score,
                                                );
                                                
                                                setState(() {
                                                  _answeredCorrectly[_currentQuestionIndex] = isCorrect;
                                                  _gameScores[_currentQuestionIndex] = score;
                                                });
                                                
                                                // Move to next question
                                                if (_currentQuestionIndex < _questions.length - 1) {
                                                  setState(() {
                                                    _currentQuestionIndex++;
                                                    _currentAttempt = 1;
                                                    _isCardGameComplete = false; // Reset for next question
                                                  });
                                                  _loadCurrentQuestionAttempt().then((_) => _startQuestionTimer());
                                                } else {
                                                  _submitQuiz();
                                                }
                                              },
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      
                                      // Handle multiple choice questions
                                      // Get the selected answer
                                      final selectedIndex = _selectedAnswers[_currentQuestionIndex];
                                      if (selectedIndex == null) return;
                                      
                                      final optionsData = List<Map<String, dynamic>>.from(question['options_data'] ?? []);
                                      
                                      // Check if answer is correct
                                      final isCorrect = selectedIndex < optionsData.length && 
                                                       optionsData[selectedIndex]['is_correct'] == true;
                                      
                                      // Stop timer
                                      _questionTimer?.cancel();
                                      
                                      if (isCorrect) {
                                        // Calculate and record points
                                        final points = _calculatePoints(_currentQuestionIndex);
                                        _recordAnswerWithPoints(true, _currentQuestionIndex);
                                        _questionPoints[_currentQuestionIndex] = points;
                                        
                                        // Mark as answered correctly
                                        setState(() {
                                          _answeredCorrectly[_currentQuestionIndex] = true;
                                        });
                                        
                                        // Save progress to database
                                        final options = List<String>.from(question['options'] ?? []);
                                        final selectedAnswerText = selectedIndex < options.length 
                                            ? options[selectedIndex] 
                                            : '';
                                        await _saveQuestionProgress(
                                          questionIndex: _currentQuestionIndex,
                                          question: question,
                                          isCorrect: true,
                                          userAnswer: {
                                            'type': 'mcq',
                                            'selected_index': selectedIndex,
                                            'selected_answer': selectedAnswerText,
                                          },
                                          pointsEarned: points,
                                        );
                                        
                                        // Show celebration
                                        await Future.delayed(const Duration(milliseconds: 300));
                                        if (mounted) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            barrierColor: Colors.black.withOpacity(0.7),
                                            builder: (context) => CelebrationWidget(
                                              show: true,
                                              points: points,
                                              onComplete: () {
                                                Navigator.of(context).pop();
                                                // Move to next question
                                                if (_currentQuestionIndex < _questions.length - 1) {
                                                  setState(() {
                                                    _currentQuestionIndex++;
                                                    _currentAttempt = 1;
                                                  });
                                                  _loadCurrentQuestionAttempt().then((_) => _startQuestionTimer());
                                                } else {
                                                  // Quiz complete
                                                  _submitQuiz();
                                                }
                                              },
                                            ),
                                          );
                                        }
                                      } else {
                                        // Wrong answer
                                        if (_currentAttempt < _maxAttempts) {
                                          // Save failed attempt progress
                                          final options = List<String>.from(question['options'] ?? []);
                                          final selectedAnswerText = selectedIndex < options.length 
                                              ? options[selectedIndex] 
                                              : '';
                                          
                                          // We don't await this to avoid UI delay, but it runs in background
                                          _saveQuestionProgress(
                                            questionIndex: _currentQuestionIndex,
                                            question: question,
                                            isCorrect: false,
                                            userAnswer: {
                                              'type': 'mcq',
                                              'selected_index': selectedIndex,
                                              'selected_answer': selectedAnswerText,
                                            },
                                            pointsEarned: 0,
                                            status: 'pending',
                                          );

                                          // Show retry dialog
                                          _showRetryDialog();
                                        } else {
                                          // Max attempts reached
                                          _recordAnswerWithPoints(false, _currentQuestionIndex);
                                          _questionPoints[_currentQuestionIndex] = 0;
                                          
                                          setState(() {
                                            _answeredCorrectly[_currentQuestionIndex] = false;
                                          });
                                          
                                          // Save progress to database
                                          final options = List<String>.from(question['options'] ?? []);
                                          final selectedAnswerText = selectedIndex < options.length 
                                              ? options[selectedIndex] 
                                              : '';
                                          await _saveQuestionProgress(
                                            questionIndex: _currentQuestionIndex,
                                            question: question,
                                            isCorrect: false,
                                            userAnswer: {
                                              'type': 'mcq',
                                              'selected_index': selectedIndex,
                                              'selected_answer': selectedAnswerText,
                                            },
                                            pointsEarned: 0,
                                          );
                                          
                                          _showNoPointsDialog();
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                _currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Submit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to detect if a card_match question should use the Card Flip game
  bool _isFlipCardGame(Map<String, dynamic> question) {
    final options = question['options'];
    if (options == null || options is! List || options.isEmpty) return false;
    
    if (options[0] is Map) {
      final firstItem = options[0] as Map;
      return firstItem.containsKey('question') && firstItem.containsKey('answer');
    }
    
    return false;
  }

  // Helper method to build card pairs for the Card Flip game
  List<Map<String, dynamic>> _buildCardPairs(Map<String, dynamic> question) {
    final options = question['options'];
    if (options == null || options is! List) return [];
    
    return options.map<Map<String, dynamic>>((pair) {
      return {
        'id': pair['id'],
        'left': pair['question'],
        'right': pair['answer'],
        'left_icon': null,
        'right_icon': null,
      };
    }).toList();
  }


  Widget _buildMultipleChoiceOptions(Map<String, dynamic> question) {
    final List<dynamic> options = question['options'] ?? [];
    final List<dynamic> optionsData = question['options_data'] ?? [];
    final List<Color> optionColors = [
      const Color(0xFFF08A7E), // Coral
      const Color(0xFF6BCB9F), // Teal
      const Color(0xFFF8C67D), // Yellow
      const Color(0xFF74C0D9), // Light Blue
    ];
    
    if (options.isEmpty) {
      return const Center(
        child: Text('No options available'),
      );
    }
    
    // Check if this question was answered and submitted
    final wasAnswered = _answeredCorrectly.containsKey(_currentQuestionIndex);
    final wasAnsweredWrong = wasAnswered && _answeredCorrectly[_currentQuestionIndex] == false;
    
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final optionColor = optionColors[index % optionColors.length];
        final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
        
        // Show feedback only if question was answered
        final showAsCorrect = wasAnswered && index < optionsData.length && optionsData[index]['is_correct'] == true;
        final showAsWrong = wasAnsweredWrong && isSelected;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              // Don't allow changing answer if already answered
              if (_answeredCorrectly.containsKey(_currentQuestionIndex)) {
                return;
              }
              
              // Just record the selection, don't show feedback yet
              setState(() {
                _selectedAnswers[_currentQuestionIndex] = index;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: showAsCorrect 
                    ? const Color(0xFF6BCB9F).withOpacity(0.3) 
                    : showAsWrong 
                        ? const Color(0xFFF08A7E).withOpacity(0.3)
                        : isSelected ? optionColor : Colors.white,
                border: Border.all(
                  color: showAsCorrect 
                      ? const Color(0xFF6BCB9F) 
                      : showAsWrong 
                          ? const Color(0xFFF08A7E)
                          : isSelected ? optionColor : const Color(0xFFE0E0E0),
                  width: isSelected || showAsCorrect || showAsWrong ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected || showAsCorrect || showAsWrong
                    ? [
                        BoxShadow(
                          color: (showAsCorrect 
                              ? const Color(0xFF6BCB9F) 
                              : showAsWrong 
                                  ? const Color(0xFFF08A7E)
                                  : optionColor).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white.withOpacity(0.2) : optionColor.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : optionColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF1A2F4B),
                      ),
                    ),
                  ),
                  if (showAsCorrect)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF6BCB9F),
                      size: 28,
                    )
                  else if (showAsWrong)
                    const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFF08A7E),
                      size: 28,
                    )
                  else if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchTheFollowing(Map<String, dynamic> question) {
    final pairs = List<Map<String, dynamic>>.from(question['match_pairs'] ?? []);
    final userMatches = _matchAnswers[_currentQuestionIndex] ?? {};
    
    // Create unique right items with index to avoid duplicate dropdown values
    final rightItemsWithIndex = pairs.asMap().entries.map((entry) {
      return '${entry.value['right']}|${entry.key}';
    }).toList();
    
    // Fun colors for each pair matching the theme accents
    final List<Color> pairColors = [
      const Color(0xFFF08A7E), // Coral
      const Color(0xFF6BCB9F), // Teal
      const Color(0xFFF8C67D), // Yellow
      const Color(0xFF74C0D9), // Light Blue
      const Color(0xFF95E1D3), // Mint
      const Color(0xFFFF9A76), // Orange
    ];

    return Column(
      children: pairs.asMap().entries.map((entry) {
        final index = entry.key;
        final pair = pairs[index];
        final leftItem = pair['left'] as String;
        final selectedRight = userMatches[leftItem];
        final pairColor = pairColors[index % pairColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: pairColor.withOpacity(0.5), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Left Item (Question)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: pairColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: pairColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: pairColor, width: 2),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: pairColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            leftItem,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2F4B), // Navy
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(Icons.arrow_downward_rounded, color: Colors.grey),
                  ),

                  // Right Item Dropdown (Answer)
                  Container(
                    decoration: BoxDecoration(
                      color: selectedRight != null ? pairColor.withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedRight != null ? pairColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedRight,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: 'Select Match',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.bold),
                        prefixIcon: Icon(
                          selectedRight != null ? Icons.link : Icons.link_off,
                          color: selectedRight != null ? pairColor : Colors.grey[400],
                        ),
                      ),
                      dropdownColor: Colors.white,
                      icon: Icon(Icons.arrow_drop_down_circle, color: pairColor),
                      items: rightItemsWithIndex.map((itemWithIndex) {
                        final displayValue = itemWithIndex.split('|')[0];
                        return DropdownMenuItem(
                          value: itemWithIndex,
                          child: Text(
                            displayValue,
                            style: TextStyle(
                              fontSize: 16,
                              color: const Color(0xFF1A2F4B),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (_matchAnswers[_currentQuestionIndex] == null) {
                            _matchAnswers[_currentQuestionIndex] = {};
                          }
                          _matchAnswers[_currentQuestionIndex]![leftItem] = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsScreen() {
    final int totalQuestions = _questions.length;
    // Calculate total score from time-based points
    final int totalScore = _questionPoints.values.fold(0, (sum, points) => sum + points);
    // Count only correct answers (points > 0)
    final int correctAnswers = _questionPoints.values.where((points) => points > 0).length;
    
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF9E6), // Very light yellow
                  Color(0xFFF4EF8B), // Main yellow #f4ef8b
                  Color(0xFFE8D96F), // Darker yellow
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // Big icon reaction based on score
                    Icon(
                      _getScoreIcon(correctAnswers, totalQuestions),
                      size: 100,
                      color: _getPrimaryColor(correctAnswers, totalQuestions),
                    ),
                    const SizedBox(height: 16),
                    
                    // Fun title with emoji
                    Text(
                      _getScoreTitle(correctAnswers, totalQuestions),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Score display card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A2F4B).withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFF8C67D).withOpacity(0.5), // Yellow border
                          width: 3,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'YOUR SCORE',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1A2F4B),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$totalScore',
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF08A7E), // Coral
                              height: 1,
                            ),
                          ),
                          Text(
                            'POINTS',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF1A2F4B).withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6BCB9F).withOpacity(0.2), // Light Teal
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '$correctAnswers / $totalQuestions Correct',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF1A2F4B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Fun message
                    Text(
                      _getEncouragementMessage(correctAnswers, totalQuestions),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Return to Dashboard button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Return to dashboard
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6), // Purple
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Return to Dashboard',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ),
        ),
        // Celebration overlay
        CelebrationWidget(
          show: _showCelebration,
          onComplete: () {
            setState(() => _showCelebration = false);
          },
        ),
      ],
    );
  }

  // Helper methods for fun UI elements
  IconData _getScoreIcon(int correct, int total) {
    final percentage = (correct / total) * 100;
    if (percentage == 100) return Icons.emoji_events_rounded; // Trophy
    if (percentage >= 90) return Icons.star_rounded; // Star
    if (percentage >= 70) return Icons.sentiment_very_satisfied_rounded; // Happy
    if (percentage >= 50) return Icons.thumb_up_rounded; // Thumbs up
    return Icons.sentiment_neutral_rounded; // Neutral
  }

  String _getScoreEmoji(int correct, int total) {
    final percentage = (correct / total) * 100;
    if (percentage == 100) return '🏆';
    if (percentage >= 90) return '🌟';
    if (percentage >= 70) return '😊';
    if (percentage >= 50) return '💪';
    return '😅';
  }

  String _getScoreTitle(int correct, int total) {
    final percentage = (correct / total) * 100;
    if (percentage == 100) return 'PERFECT! 🎉';
    if (percentage >= 90) return 'AMAZING! ✨';
    if (percentage >= 70) return 'GREAT JOB! 🎊';
    if (percentage >= 50) return 'GOOD EFFORT! 💫';
    return 'KEEP PRACTICING! 📚';
  }

  String _getEncouragementMessage(int correct, int total) {
    final percentage = (correct / total) * 100;
    if (percentage == 100) return 'You\'re a quiz master! 🎓';
    if (percentage >= 90) return 'Almost perfect! Keep it up! 🚀';
    if (percentage >= 70) return 'You\'re doing great! 🌈';
    if (percentage >= 50) return 'Nice try! Practice makes perfect! 💡';
    return 'Don\'t give up! You\'ll get better! 🌟';
  }

  List<Color> _getGradientColors(int correct, int total) {
    final percentage = (correct / total) * 100;
    if (percentage >= 90) {
      return [const Color(0xFFFF6B9D), const Color(0xFFFFB347)]; // Pink to Orange
    } else if (percentage >= 70) {
      return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)]; // Turquoise to Green
    } else if (percentage >= 50) {
      return [const Color(0xFF9B59B6), const Color(0xFF6B5CE7)]; // Purple
    } else {
      return [const Color(0xFFFF9A76), const Color(0xFFFF6B9D)]; // Coral to Pink
    }
  }

  Color _getPrimaryColor(int correct, int total) {
    final percentage = (correct / total) * 100;
    if (percentage >= 90) return const Color(0xFFFF6B9D);
    if (percentage >= 70) return const Color(0xFF4ECDC4);
    if (percentage >= 50) return const Color(0xFF9B59B6);
    return const Color(0xFFFF9A76);
  }
}

