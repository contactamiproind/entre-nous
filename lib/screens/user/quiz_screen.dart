import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/progress_service.dart';
import '../../services/pathway_service.dart';
import '../../widgets/celebration_widget.dart';
import '../../widgets/card_match_question_widget.dart';
import 'package:audioplayers/audioplayers.dart';

class QuizScreen extends StatefulWidget {
  final Map<String, dynamic> level;
  final String pathwayName;
  final String pathwayId;

  const QuizScreen({
    super.key,
    required this.level,
    required this.pathwayName,
    required this.pathwayId,
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
  static const int _questionTimeLimit = 30; // 30 seconds per question
  int _questionStartTime = 30; // Track time when question started
  
  // Attempt tracking
  int _currentAttempt = 1;
  static const int _maxAttempts = 2;

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
    });
    // Reset timer to 30 seconds and restart
    _startQuestionTimer();
  }

  int _calculatePoints() {
    // Calculate time used (in seconds)
    final timeUsed = _questionStartTime - _remainingSeconds;
    final timePercentage = timeUsed / _questionStartTime;
    
    // Time-based scoring:
    // < 50% time used: Full points (100)
    // 50-75% time used: Half points (50)
    // > 75% time used: Quarter points (25)
    if (timePercentage < 0.5) {
      return 100; // Fast answer - full points
    } else if (timePercentage < 0.75) {
      return 50; // Moderate speed - half points
    } else {
      return 25; // Slow answer - quarter points
    }
  }

  void _recordAnswerWithPoints(bool isCorrect, int questionIndex) {
    // Record points for the specified question based on answer correctness and speed
    
    // If user has exceeded max attempts, award 0 points regardless of correctness
    if (_currentAttempt > _maxAttempts) {
      _questionPoints[questionIndex] = 0;
      debugPrint('⚠️ Question $questionIndex: 0 points (exceeded max attempts)');
      return;
    }
    
    if (isCorrect) {
      // Check if we have the answer time stored
      if (_questionAnswerTimes.containsKey(questionIndex)) {
        final remainingTime = _questionAnswerTimes[questionIndex]!;
        final timeUsed = _questionStartTime - remainingTime;
        final timePercentage = timeUsed / _questionStartTime;
        
        // Calculate points based on time used
        int points;
        if (timePercentage < 0.5) {
          points = 100; // Fast answer - full points
        } else if (timePercentage < 0.75) {
          points = 50; // Moderate speed - half points
        } else {
          points = 25; // Slow answer - quarter points
        }
        
        _questionPoints[questionIndex] = points;
        debugPrint('✅ Question $questionIndex: Earned $points points (answered with ${remainingTime}s remaining, ${timePercentage.toStringAsFixed(1)}% time used)');
      } else {
        // Fallback: no timing data, give full points
        _questionPoints[questionIndex] = 100;
        debugPrint('✅ Question $questionIndex: Earned 100 points (no timing data)');
      }
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

  Future<void> _loadQuestions() async {
    try {
      
      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      // Get level number from widget
      final levelNumber = widget.level['level_number'] ?? 1;
      
      debugPrint('🔍 Loading assigned questions for user ${user.id}');
      debugPrint('  Department ID: ${widget.pathwayId}');
      debugPrint('  Level number: $levelNumber');
      
      // Load questions from usr_progress (assigned questions only)
      final progressData = await Supabase.instance.client
          .from('usr_progress')
          .select('id, question_id, question_text, question_type, difficulty, points, status, user_answer, is_correct')
          .eq('user_id', user.id)
          .eq('dept_id', widget.pathwayId)
          .eq('level_number', levelNumber)
          .order('created_at');
      
      debugPrint('📊 Found ${progressData.length} assigned questions for this level');

      List<Map<String, dynamic>> questions = [];
      
      // For each progress entry, load the full question details including options
      for (var progress in progressData) {
        // Load full question data including options from questions table
        final questionData = await Supabase.instance.client
            .from('questions')
            .select('id, title, description, options, correct_answer')
            .eq('id', progress['question_id'])
            .single();
        
        // Infer question type from title AND options structure
        String inferredType = 'multiple_choice'; // default
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
        } else if (title.contains('match')) {
          // Only set to match_following if it's not already identified as card_match
          inferredType = 'match_following';
        }
        
        debugPrint('   Question type inferred: $inferredType (title: $title)');
        
        
        // Extract options from the question data
      List<String> options = [];
      List<Map<String, dynamic>> optionsData = [];
      
      if (questionData['options'] != null) {
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
        
        debugPrint('  Question ${progress['question_id']}: loaded ${options.length} options');
      }  
        
        questions.add({
          'id': progress['question_id'],
          'progress_id': progress['id'], // Store usr_progress ID for updates
          'title': progress['question_text'],
          'description': questionData['description'],
          'difficulty': progress['difficulty'],
          'points': progress['points'],
          'status': progress['status'],
          'user_answer': progress['user_answer'],
          'is_correct': progress['is_correct'],
          'options': inferredType == 'card_match' ? questionData['options'] : options, // Keep Map for card_match, use List for others
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
      });
      
      // Start timer for first question
      if (questions.isNotEmpty) {
        _startQuestionTimer();
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
      
      if (questionType == 'card_match') {
        final score = _gameScores[i] ?? 0;
        debugPrint('🎮 Card Match Question $i: Score = $score');
        totalScore += score;
        // Count as correct if score is 25 or higher (out of max ~60)
        if (score >= 25) {
          debugPrint('✅ Card Match counted as CORRECT (score >= 25)');
          correctCount++;
          _answeredCorrectly[i] = true;
        } else {
          debugPrint('❌ Card Match counted as WRONG (score < 25)');
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
        for (int i = 0; i < _questions.length; i++) {
           // Re-calculate or reuse calculation (Re-calculating specifically for creating the record payload)
           final question = _questions[i];
           final int questionValue = question['points'] ?? 10; // Define questionValue
           final questionType = question['question_type'] ?? 'multiple_choice';
           
           Map<String, dynamic> userAnswer = {};
           bool isCorrect = false; // Need to re-derive for saving record

            if (questionType == 'multiple_choice') {
              final selectedIndex = _selectedAnswers[i];
              final options = List<String>.from(question['options'] ?? []);
              final optionsData = List<Map<String, dynamic>>.from(question['options_data'] ?? []);
               if (selectedIndex != null && selectedIndex < options.length && selectedIndex < optionsData.length) {
                  final selectedAnswerText = options[selectedIndex];
                  isCorrect = optionsData[selectedIndex]['is_correct'] == true;
                  userAnswer = {
                    'type': 'mcq',
                    'selected_index': selectedIndex,
                    'selected_answer': selectedAnswerText,
                  };
               }
            } else if (questionType == 'match_following') {
               // ... Match logic ...
               final pairs = List<Map<String, dynamic>>.from(question['match_pairs'] ?? []);
               final userMatches = _matchAnswers[i] ?? {};
               bool allCorrect = true;
               for (var pair in pairs) {
                 final left = pair['left'] as String;
                 final correctRight = pair['right'] as String;
                 if (userMatches[left]?.split('|')[0] != correctRight) { allCorrect = false; break; }
               }
               isCorrect = allCorrect && userMatches.length == pairs.length;
               userAnswer = {'type': 'match_following', 'matches': userMatches};
             }

           // Calculate time-based points for correct answers
           int pointsEarned = 0;
           if (isCorrect) {
             // Use time-based scoring if question was answered (has tracked time)
             if (_questionPoints.containsKey(i)) {
               pointsEarned = _questionPoints[i]!;
             } else {
               // Fallback: calculate points now (for questions answered before timer implementation)
               pointsEarned = _calculatePoints();
               _questionPoints[i] = pointsEarned;
             }
           }

           await _progressService.saveQuestionAnswer(
             userId: user.id,
             departmentId: widget.level['department_id'] ?? widget.level['pathway_id'] ?? widget.level['dept_id'] ?? '',
             usrDeptId: widget.level['usr_dept_id'] ?? '',
             questionId: question['id'],
             userAnswer: userAnswer.toString(),
             isCorrect: isCorrect,
             scoreEarned: pointsEarned, // Use time-based points
           );
         }

        if (widget.pathwayName.toLowerCase() == 'orientation') {
          await PathwayService().markOrientationComplete(user.id);
        }

        // Auto-unlock next level if user passed (>= 70%)
        if (percentage >= 70) {
          try {
            final currentLevelNumber = widget.level['level_number'] ?? 1;
            final nextLevelNumber = currentLevelNumber + 1;
            
            debugPrint('🔓 Unlocking next level: $nextLevelNumber');
            
            // Update usr_dept to unlock next level
            await Supabase.instance.client
                .from('usr_dept')
                .update({'current_level': nextLevelNumber})
                .eq('user_id', user.id)
                .eq('dept_id', widget.pathwayId);
            
            debugPrint('✅ Next level unlocked successfully!');
          } catch (e) {
            debugPrint('Error unlocking next level: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving quiz result (Background): $e');
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
        appBar: AppBar(title: Text(widget.level['title'] ?? widget.level['level_name'] ?? 'Level ${widget.level['level_number']}')),
        body: const Center(
          child: Text('No questions available for this level yet.'),
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
    bool isAnswered = false;
    if (questionType == 'multiple_choice') {
      isAnswered = _selectedAnswers[_currentQuestionIndex] != null;
    } else {
      final pairs = List<Map<String, dynamic>>.from(question['match_pairs'] ?? []);
      final userMatches = _matchAnswers[_currentQuestionIndex] ?? {};
      isAnswered = userMatches.length == pairs.length;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6EC1E4), // Light blue
              Color(0xFF9BA8E8), // Purple-blue
              Color(0xFFE8A8D8), // Pink
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        '${widget.pathwayName} - Level ${widget.level['level_number']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Bar
                      LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _questions.length,
                        color: const Color(0xFFFBBF24), // Yellow
                        backgroundColor: Colors.white.withOpacity(0.3),
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 24),
                      
                      // Question Counter and Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          // Timer Display - Enhanced visibility
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            transform: _remainingSeconds <= 10 
                                ? (Matrix4.identity()..scale(1.15))
                                : Matrix4.identity(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _remainingSeconds <= 10 
                                  ? Colors.red
                                  : const Color(0xFFFBBF24),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _remainingSeconds <= 10
                                      ? Colors.red.withOpacity(0.8)
                                      : const Color(0xFFFBBF24).withOpacity(0.6),
                                  blurRadius: 16,
                                  spreadRadius: 4,
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
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$_remainingSeconds',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: _remainingSeconds <= 10 ? 32 : 28,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  's',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: _remainingSeconds <= 10 ? 20 : 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
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
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (question['description'] != null && question['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            question['description'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ],
                      const SizedBox(height: 32),
                      
                      // Question Content (Scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          child: questionType == 'card_match'
                              ? CardMatchQuestionWidget(
                                  questionData: question,
                                  onAnswerSubmitted: (score, isCorrect) {
                                    setState(() {
                                      _gameScores[_currentQuestionIndex] = score;
                                      if (_currentQuestionIndex < _questions.length - 1) {
                                        _currentQuestionIndex++;
                                      } else {
                                        _submitQuiz();
                                      }
                                    });
                                  },
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
                                  : () {
                                      if (_currentQuestionIndex < _questions.length - 1) {
                                        setState(() => _currentQuestionIndex++);
                                        _startQuestionTimer(); // Restart timer for next question
                                      } else {
                                        _questionTimer?.cancel(); // Stop timer before submitting
                                        _submitQuiz();
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
    
    // Check if this question was answered and submitted (feedback only after submit)
    final wasAnswered = _answeredCorrectly.containsKey(_currentQuestionIndex);
    final wasAnsweredWrong = wasAnswered && _answeredCorrectly[_currentQuestionIndex] == false;
    
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
        final optionColor = optionColors[index % optionColors.length];
        
        // Check if this is the correct answer
        final isCorrectAnswer = index < optionsData.length && 
                                optionsData[index]['is_correct'] == true;
        
        // Show correct answer with green border only after submit if user answered wrong
        final showAsCorrect = wasAnsweredWrong && isCorrectAnswer;
        final showAsWrong = wasAnsweredWrong && isSelected && !isCorrectAnswer;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
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
                  width: (showAsCorrect || showAsWrong) ? 3 : isSelected ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: optionColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : optionColor,
                          fontSize: 18,
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
                  Color(0xFF6EC1E4),
                  Color(0xFF9BA8E8),
                  Color(0xFFE8A8D8),
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
                    
                    // Colorful button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (correctAnswers / totalQuestions >= 0.7) {
                            // NEXT CHALLENGE - Go directly to next level
                            final currentLevelNumber = widget.level['level_number'] ?? 1;
                            final nextLevelNumber = currentLevelNumber + 1;
                            
                            // Try to get next level data
                            try {
                              debugPrint('🔍 Looking for next level: $nextLevelNumber in pathway: ${widget.pathwayId}');
                              
                              final nextLevelData = await Supabase.instance.client
                                  .from('departments')
                                  .select('id, dept_id, title, level_number, description')
                                  .eq('dept_id', widget.pathwayId)
                                  .eq('level_number', nextLevelNumber)
                                  .maybeSingle();
                              
                              debugPrint('📊 Next level data: $nextLevelData');
                              
                              if (nextLevelData != null && mounted) {
                                // Add required fields for QuizScreen
                                nextLevelData['department_id'] = widget.pathwayId;
                                nextLevelData['pathway_id'] = widget.pathwayId;
                                nextLevelData['dept_id'] = widget.pathwayId;
                                
                                // Navigate directly to next level quiz
                                debugPrint('✅ Navigating to next level quiz');
                                
                                // Pop current quiz screen and pathway detail screen, then push next level
                                Navigator.of(context).popUntil((route) => route.isFirst);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizScreen(
                                      level: nextLevelData,
                                      pathwayName: widget.pathwayName,
                                      pathwayId: widget.pathwayId,
                                    ),
                                  ),
                                );
                              } else {
                                // No more levels, go back to dashboard
                                debugPrint('ℹ️ No more levels found, returning to dashboard');
                                if (mounted) Navigator.pop(context, true);
                              }
                            } catch (e) {
                              debugPrint('❌ Error loading next level: $e');
                              if (mounted) Navigator.pop(context, true);
                            }
                          } else {
                            // TRY AGAIN - Return to first wrong question
                            if (_firstWrongQuestionIndex != null) {
                              setState(() {
                                _currentQuestionIndex = _firstWrongQuestionIndex!;
                                _showResults = false;
                                _showCelebration = false;
                                _answeredCorrectly.clear(); // Clear feedback state for clean retry
                              });
                            } else {
                              // Fallback: restart from beginning
                              setState(() {
                                _currentQuestionIndex = 0;
                                _showResults = false;
                                _answeredCorrectly.clear(); // Clear feedback state for clean retry
                                _showCelebration = false;
                              });
                            }
                          }
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              correctAnswers / totalQuestions >= 0.7 ? 'NEXT CHALLENGE 🚀' : 'TRY AGAIN 💪',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
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
