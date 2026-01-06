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
  bool _isSubmitting = false;
  Map<int, int> _selectedAnswers = {}; // question_index -> answer_index
  bool _showResults = false;
  bool _showCelebration = false;
  
  Map<int, Map<String, String?>> _matchAnswers = {}; // question_index -> {left_item -> selected_right_item}
  Map<int, int> _gameScores = {}; // question_index -> score (for interactive games)
  bool _showLevelIntro = true; // Show gamified intro logic

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
        
        // Extract options from the question data
      List<String> options = [];
      List<Map<String, dynamic>> optionsData = [];
      
      if (questionData['options'] != null) {
        final optionsJson = questionData['options'] as List<dynamic>;
        final correctAnswer = questionData['correct_answer']?.toString();
        
        for (var opt in optionsJson) {
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
              'is_correct': correctAnswer != null && opt == correctAnswer,
            });
          }
        }
      }  
        
        debugPrint('  Question ${progress['question_id']}: loaded ${options.length} options');
        
        questions.add({
          'id': progress['question_id'],
          'progress_id': progress['id'], // Store usr_progress ID for updates
          'title': progress['question_text'],
          'description': progress['question_type'],
          'question_type': 'multiple_choice', // Default, can be enhanced
          'difficulty': progress['difficulty'],
          'points': progress['points'],
          'status': progress['status'],
          'user_answer': progress['user_answer'],
          'is_correct': progress['is_correct'],
          'options': options, // Add the loaded options
          'options_data': optionsData, // Store full option data with is_correct flags
        });
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
        _matchAnswers = {};
        _gameScores = {};
      });
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
    setState(() => _isSubmitting = true);

    int correctCount = 0;
    int totalScore = 0;
    final int questionValue = 100; // Customizable per question logic if needed

    // 1. Calculate Score first
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final questionType = question['question_type'] ?? 'multiple_choice';
      
      bool isCorrect = false;
      
      if (questionType == 'multiple_choice') {
        final selectedIndex = _selectedAnswers[i];
        final options = List<String>.from(question['options'] ?? []);
        final optionsData = List<Map<String, dynamic>>.from(question['options_data'] ?? []);
        
        if (selectedIndex != null && selectedIndex < options.length && selectedIndex < optionsData.length) {
          final selectedAnswerText = options[selectedIndex];
          final isCorrectOption = optionsData[selectedIndex]['is_correct'] == true;
          
          debugPrint('Checking Answer: "$selectedAnswerText" (Index: $selectedIndex, Is Correct: $isCorrectOption)');
          
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

      if (questionType == 'card_match') {
        final score = _gameScores[i] ?? 0;
        totalScore += score;
        if (score >= 40) correctCount++; // threshold for "correct" status
      } else {
        if (isCorrect) {
          correctCount++;
          totalScore += questionValue;
        }
      }
    }

    // 2. Show Results & Celebration IMMEDIATELY
    final percentage = _questions.isEmpty ? 0.0 : (correctCount / _questions.length) * 100;
    debugPrint('Quiz completed! Score: $percentage%');
    
    setState(() {
      _score = totalScore;
      _showResults = true;
      _isSubmitting = false;
      
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

          await _progressService.saveQuestionAnswer(
            userId: user.id,
            departmentId: widget.level['department_id'] ?? widget.level['pathway_id'] ?? widget.level['dept_id'] ?? '',
            questionId: question['id'],
            questionOrder: i + 1,
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            pointsEarned: isCorrect ? questionValue : 0,
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
            
            // Update user_progress to unlock next level
            await Supabase.instance.client
                .from('user_progress')
                .update({'current_level': nextLevelNumber})
                .eq('user_id', user.id);
            
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
      backgroundColor: const Color(0xFFFDF8F0), // Cream
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.pathwayName} - Level ${widget.level['level_number']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent, // Transparent to show cream
        foregroundColor: const Color(0xFF1A2F4B), // Navy
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              color: const Color(0xFF6BCB9F), // Pastel Teal
              backgroundColor: const Color(0xFF1A2F4B).withOpacity(0.1),
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 24),
            
            // Question Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8C67D).withOpacity(0.3), // Light Yellow pill
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: const TextStyle(
                  color: Color(0xFF1A2F4B),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
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
                  color: const Color(0xFF1A2F4B),
                  fontSize: 22,
                  height: 1.3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (question['description'] != null && question['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  question['description'],
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF1A2F4B).withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            const SizedBox(height: 32),
            
            // Question Content (Multiple Choice, Match, or Card Match)
            Expanded(
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
                  : questionType == 'multiple_choice'
                      ? _buildMultipleChoiceOptions(question)
                      : _buildMatchTheFollowing(question),
            ),
            
            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _currentQuestionIndex--);
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
                          } else {
                            _submitQuiz();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    _currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Submit',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(Map<String, dynamic> question) {
    final List<dynamic> options = question['options'] ?? [];
    final List<Color> optionColors = [
      const Color(0xFFF08A7E), // Coral
      const Color(0xFF6BCB9F), // Teal
      const Color(0xFFF8C67D), // Yellow
      const Color(0xFF74C0D9), // Light Blue
    ];
    
    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
        final optionColor = optionColors[index % optionColors.length];
        
        return InkWell(
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
              color: isSelected ? optionColor : Colors.white,
              border: Border.all(
                color: isSelected ? optionColor : const Color(0xFFE0E0E0),
                width: isSelected ? 3 : 2,
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
                    options[index],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF1A2F4B), // Navy
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
              ],
            ),
          ),
        );
      },
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

    return ListView.separated(
      itemCount: pairs.length,
      separatorBuilder: (c, i) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final pair = pairs[index];
        final leftItem = pair['left'] as String;
        final selectedRight = userMatches[leftItem];
        final pairColor = pairColors[index % pairColors.length];

        return Container(
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
        );
      },
    );
  }

  Widget _buildResultsScreen() {
    final int totalQuestions = _questions.length;
    final int correctAnswers = _score ~/ 100; // Assuming 100 points per question
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFFDF8F0), // Cream
          body: SafeArea(
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
                        color: Color(0xFF1A2F4B), // Navy
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
                            '$_score',
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
                      style: TextStyle(
                        fontSize: 18,
                        color: const Color(0xFF1A2F4B).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Colorful button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6BCB9F), // Teal Logic
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
