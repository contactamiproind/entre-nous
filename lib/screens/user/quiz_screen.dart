import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/game_types.dart';
import '../../services/quiz_service.dart';
import '../../services/progress_service.dart';
import '../../services/pathway_service.dart';
import '../../widgets/celebration_widget.dart';
import '../../widgets/card_flip_game_widget.dart';
import '../../widgets/sequence_builder_widget.dart';
import '../../widgets/budget_allocation_widget.dart';
import '../../widgets/mcq_question_widget.dart';
import '../../widgets/match_following_widget.dart';
import 'package:audioplayers/audioplayers.dart';

/// Modular quiz screen that delegates to per-type widget components
/// and uses QuizService for all API calls.
class QuizScreen extends StatefulWidget {
  final String category;
  final String? subcategory;
  final int? startQuestionIndex;
  final int? levelNumber;

  const QuizScreen({
    super.key,
    required this.category,
    this.subcategory,
    this.startQuestionIndex,
    this.levelNumber,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  final ProgressService _progressService = ProgressService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- State ---
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showResults = false;
  bool _showCelebration = false;

  // Per-question state
  Map<int, int> _selectedAnswers = {};
  Map<int, bool> _answeredCorrectly = {};
  Map<int, Map<String, String?>> _matchAnswers = {};
  Map<int, int> _gameScores = {};
  Map<int, int> _questionPoints = {};

  // Timer
  Timer? _questionTimer;
  int _remainingSeconds = 30;
  int _questionTimeLimit = 30;
  int _questionStartTime = 30;

  // Scoring thresholds
  double _fullPointsThreshold = 0.5;
  double _halfPointsThreshold = 0.75;

  // Attempts
  int _currentAttempt = 1;
  static const int _maxAttempts = 2;

  // Tracking
  String? _deptId;
  bool _isCardGameComplete = false;

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

  // ─── TIMER ───────────────────────────────────────────────

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    setState(() {
      _remainingSeconds = _questionTimeLimit;
      _questionStartTime = _questionTimeLimit;
    });
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds == 10) HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
        _handleTimeExpired();
      }
    });
  }

  void _handleTimeExpired() {
    _questionTimer?.cancel();
    if (_currentAttempt < _maxAttempts) {
      _showRetryDialog(isTimeUp: true);
    } else {
      _showNoPointsDialog();
    }
  }

  // ─── DIALOGS ─────────────────────────────────────────────

  void _showRetryDialog({bool isTimeUp = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(isTimeUp ? Icons.timer_off : Icons.close_rounded,
              color: const Color(0xFFF08A7E), size: 28),
          const SizedBox(width: 12),
          Text(isTimeUp ? 'Time\'s Up!' : 'Wrong Answer'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isTimeUp
              ? 'You ran out of time for this question.'
              : 'That wasn\'t the right answer. Give it another try!',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text('Attempt $_currentAttempt of $_maxAttempts',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6))),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _retryQuestion();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white),
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
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.info_outline, color: Color(0xFFF08A7E), size: 28),
          SizedBox(width: 12),
          Flexible(child: Text('No Points Earned')),
        ]),
        content: const Text(
            'You\'ve used both attempts. Moving to the next question.',
            style: TextStyle(fontSize: 15)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _advanceToNext();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _retryQuestion() {
    setState(() {
      _currentAttempt++;
      _selectedAnswers.remove(_currentQuestionIndex);
    });
    _startQuestionTimer();
  }

  void _advanceToNext() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentAttempt = 1;
        _isCardGameComplete = false;
      });
      _loadCurrentQuestionAttempt().then((_) => _startQuestionTimer());
    } else {
      _submitQuiz();
    }
  }

  // ─── SCORING ─────────────────────────────────────────────

  int _calculatePoints(int qi) {
    if (qi >= 0 && qi < _questions.length) {
      return (_questions[qi]['points'] as int?) ?? 10;
    }
    return 10;
  }

  void _recordAnswerWithPoints(bool isCorrect, int qi) {
    if (_currentAttempt > _maxAttempts) {
      _questionPoints[qi] = 0;
      return;
    }
    _questionPoints[qi] = isCorrect ? _calculatePoints(qi) : 0;
  }

  // ─── DATA LOADING (via QuizService) ──────────────────────

  Future<void> _loadQuestions() async {
    try {
      // Load settings
      final settings = await _quizService.loadSettings();
      if (mounted) {
        setState(() {
          _questionTimeLimit = settings.timerSeconds;
          _remainingSeconds = _questionTimeLimit;
          _questionStartTime = _questionTimeLimit;
          _fullPointsThreshold = settings.fullPointsThreshold;
          _halfPointsThreshold = settings.halfPointsThreshold;
        });
      }

      // Load questions
      final result = await _quizService.loadQuestions(
        category: widget.category,
        subcategory: widget.subcategory,
        levelNumber: widget.levelNumber,
      );

      _deptId = result.deptId;

      setState(() {
        _questions = result.questions;
        _isLoading = false;
        _matchAnswers = {};
        _gameScores = {};
        if (widget.startQuestionIndex != null &&
            widget.startQuestionIndex! < result.questions.length) {
          _currentQuestionIndex = widget.startQuestionIndex!;
        }
      });

      if (result.questions.isNotEmpty) {
        _loadCurrentQuestionAttempt().then((_) => _startQuestionTimer());
      }
    } catch (e) {
      debugPrint('❌ Error loading questions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading questions: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCurrentQuestionAttempt() async {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) return;
    try {
      final qId = _questions[_currentQuestionIndex]['id'].toString();
      final info = await _quizService.loadAttemptInfo(qId);
      if (mounted) {
        setState(() {
          if (info.status == 'pending') {
            _currentAttempt = 1;
          } else if (info.status == 'answered') {
            _currentAttempt = _maxAttempts + 1;
          } else {
            _currentAttempt = info.attemptCount > 0 ? info.attemptCount : 1;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading attempt: $e');
    }
  }

  Future<void> _saveProgress({
    required Map<String, dynamic> question,
    required bool isCorrect,
    required Map<String, dynamic> userAnswer,
    required int pointsEarned,
    String status = 'answered',
  }) async {
    await _quizService.saveQuestionProgress(
      category: widget.category,
      subcategory: widget.subcategory,
      question: question,
      isCorrect: isCorrect,
      userAnswer: userAnswer,
      pointsEarned: pointsEarned,
      attemptCount: _currentAttempt,
      status: status,
    );
  }

  // ─── SUBMIT QUIZ ─────────────────────────────────────────

  Future<void> _submitQuiz() async {
    debugPrint('=== SUBMITTING QUIZ ===');
    final int totalScore = _questionPoints.values.fold(0, (s, p) => s + p);
    final int correctCount =
        _answeredCorrectly.values.where((v) => v == true).length;
    final percentage =
        _questions.isEmpty ? 0.0 : (correctCount / _questions.length) * 100;

    setState(() {
      _score = totalScore;
      _showResults = true;
      if (percentage >= 70) {
        _showCelebration = true;
        try {
          _audioPlayer.setVolume(1.0);
          _audioPlayer.play(AssetSource('sounds/success.mp3'));
        } catch (_) {}
        HapticFeedback.mediumImpact();
      }
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        if (widget.category.toLowerCase() == 'orientation') {
          await PathwayService().markOrientationComplete(user.id);
        }
        if (_deptId != null) {
          await _progressService.attemptLevelPromotion(user.id, _deptId!);
        }
      }
    } catch (e) {
      debugPrint('❌ Error in post-quiz: $e');
    }
  }

  // ─── ANSWER HANDLERS (per type) ──────────────────────────

  Future<void> _handleMcqAnswer(Map<String, dynamic> question) async {
    final selectedIndex = _selectedAnswers[_currentQuestionIndex];
    if (selectedIndex == null) return;

    final optionsData =
        List<Map<String, dynamic>>.from(question['options_data'] ?? []);
    final isCorrect = selectedIndex < optionsData.length &&
        optionsData[selectedIndex]['is_correct'] == true;

    _questionTimer?.cancel();

    final options = List<String>.from(question['options'] ?? []);
    final selectedText =
        selectedIndex < options.length ? options[selectedIndex] : '';

    if (isCorrect) {
      final points = _calculatePoints(_currentQuestionIndex);
      _recordAnswerWithPoints(true, _currentQuestionIndex);
      _questionPoints[_currentQuestionIndex] = points;
      setState(() => _answeredCorrectly[_currentQuestionIndex] = true);

      await _saveProgress(
        question: question,
        isCorrect: true,
        userAnswer: {'type': GameType.multipleChoice, 'selected_index': selectedIndex, 'selected_answer': selectedText},
        pointsEarned: points,
      );

      _showCelebrationThenAdvance(points);
    } else {
      if (_currentAttempt < _maxAttempts) {
        _saveProgress(
          question: question,
          isCorrect: false,
          userAnswer: {'type': GameType.multipleChoice, 'selected_index': selectedIndex, 'selected_answer': selectedText},
          pointsEarned: 0,
          status: 'pending',
        );
        _showRetryDialog();
      } else {
        _recordAnswerWithPoints(false, _currentQuestionIndex);
        _questionPoints[_currentQuestionIndex] = 0;
        setState(() => _answeredCorrectly[_currentQuestionIndex] = false);

        await _saveProgress(
          question: question,
          isCorrect: false,
          userAnswer: {'type': GameType.multipleChoice, 'selected_index': selectedIndex, 'selected_answer': selectedText},
          pointsEarned: 0,
        );
        _showNoPointsDialog();
      }
    }
  }

  Future<void> _handleMatchAnswer(Map<String, dynamic> question) async {
    final pairs =
        List<Map<String, dynamic>>.from(question['match_pairs'] ?? []);
    final userMatches = _matchAnswers[_currentQuestionIndex] ?? {};

    int correctCount = 0;
    for (var pair in pairs) {
      final left = pair['left'] as String;
      final correctRight = pair['right'] as String;
      final userRight = userMatches[left]?.split('|')[0];
      if (userRight == correctRight) correctCount++;
    }

    final allCorrect = correctCount == pairs.length;
    final points = allCorrect ? _calculatePoints(_currentQuestionIndex) : 0;

    _questionTimer?.cancel();
    _recordAnswerWithPoints(allCorrect, _currentQuestionIndex);
    _questionPoints[_currentQuestionIndex] = points;
    setState(() => _answeredCorrectly[_currentQuestionIndex] = allCorrect);

    await _saveProgress(
      question: question,
      isCorrect: allCorrect,
      userAnswer: {'type': GameType.matchFollowing, 'matches': userMatches, 'correct_count': correctCount, 'total_pairs': pairs.length},
      pointsEarned: points,
    );

    if (allCorrect) {
      _showCelebrationThenAdvance(points);
    } else {
      if (_currentAttempt < _maxAttempts) {
        _showRetryDialog();
      } else {
        _showNoPointsDialog();
      }
    }
  }

  Future<void> _handleGameAnswer(Map<String, dynamic> question, String type) async {
    final score = _gameScores[_currentQuestionIndex] ?? 0;
    final isCorrect = _answeredCorrectly[_currentQuestionIndex] ?? false;

    _questionTimer?.cancel();
    _questionPoints[_currentQuestionIndex] = score;

    await _saveProgress(
      question: question,
      isCorrect: isCorrect,
      userAnswer: {'type': type, 'score': score, 'time_taken': _questionTimeLimit - _remainingSeconds},
      pointsEarned: score,
    );

    _showCelebrationThenAdvance(score);
  }

  void _showCelebrationThenAdvance(int points) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => CelebrationWidget(
        show: true,
        points: points,
        onComplete: () {
          Navigator.of(ctx).pop();
          _advanceToNext();
        },
      ),
    );
  }

  // ─── NEXT BUTTON HANDLER ─────────────────────────────────

  Future<void> _onNextPressed() async {
    final question = _questions[_currentQuestionIndex];
    final type = question['question_type'] ?? GameType.multipleChoice;

    if (type == GameType.cardMatch && _isCardGameComplete) {
      await _handleGameAnswer(question, GameType.cardMatch);
    } else if (type == GameType.sequenceBuilder && _isCardGameComplete) {
      await _handleGameAnswer(question, GameType.sequenceBuilder);
    } else if (type == GameType.simulation && _isCardGameComplete) {
      await _handleGameAnswer(question, GameType.simulation);
    } else if (type == GameType.matchFollowing) {
      await _handleMatchAnswer(question);
    } else {
      // MCQ / Scenario / SingleTap
      await _handleMcqAnswer(question);
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────

  bool _isFlipCardGame(Map<String, dynamic> question) {
    final options = question['options'];
    if (options == null || options is! List || options.isEmpty) return false;
    if (options[0] is Map) {
      final first = options[0] as Map;
      return first.containsKey('question') && first.containsKey('answer');
    }
    return false;
  }

  List<Map<String, dynamic>> _buildCardPairs(Map<String, dynamic> question) {
    final options = question['options'];
    if (options == null || options is! List) return [];
    return options
        .map<Map<String, dynamic>>((p) => {
              'id': p['id'],
              'left': p['question'],
              'right': p['answer'],
              'left_icon': null,
              'right_icon': null,
            })
        .toList();
  }

  bool _isCurrentAnswered() {
    if (_questions.isEmpty) return false;
    final question = _questions[_currentQuestionIndex];
    final type = question['question_type'] ?? GameType.multipleChoice;

    if (_answeredCorrectly.containsKey(_currentQuestionIndex)) return true;

    if (GameType.isMcq(type)) {
      return _selectedAnswers[_currentQuestionIndex] != null;
    } else if (type == GameType.matchFollowing) {
      final pairs = List<Map<String, dynamic>>.from(question['match_pairs'] ?? []);
      final userMatches = _matchAnswers[_currentQuestionIndex] ?? {};
      return userMatches.length == pairs.length;
    } else if (GameType.isGame(type)) {
      return _isCardGameComplete;
    }
    return false;
  }

  // ─── BUILD ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) return _buildEmptyState();
    if (_showResults) return _buildResultsScreen();

    final question = _questions[_currentQuestionIndex];
    final type = question['question_type'] ?? GameType.multipleChoice;
    final isAnswered = _isCurrentAnswered();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF9E6), Color(0xFFF4EF8B), Color(0xFFE8D96F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionCounter(),
                      const SizedBox(height: 8),
                      _buildQuestionTitle(question, type),
                      const SizedBox(height: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildQuestionContent(question, type),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNavigationButtons(isAnswered),
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

  Widget _buildEmptyState() {
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
            colors: [Color(0xFFFFF9E6), Color(0xFFF4EF8B), Color(0xFFE8D96F)],
          ),
        ),
        child: const Center(
          child: Text('No questions available for this category yet.',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
          ),
          const Spacer(),
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
                color: const Color(0xFFFBBF24),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCounter() {
    return Row(
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
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ),
        _buildTimerBadge(),
      ],
    );
  }

  Widget _buildTimerBadge() {
    final isUrgent = _remainingSeconds <= 10;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      transform: isUrgent ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red : const Color(0xFFFBBF24),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isUrgent ? Colors.red : const Color(0xFFFBBF24)).withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUrgent ? Icons.warning_amber_rounded : Icons.timer, color: Colors.white, size: 22),
          const SizedBox(width: 6),
          Text('$_remainingSeconds',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: isUrgent ? 28 : 24, letterSpacing: 1.0)),
          const SizedBox(width: 3),
          Text('s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: isUrgent ? 18 : 16)),
        ],
      ),
    );
  }

  Widget _buildQuestionTitle(Map<String, dynamic> question, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (type == GameType.matchFollowing)
          Text('Match the Following items below!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: const Color(0xFF1A2F4B)))
        else
          Text(question['title'] ?? 'Question',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.black, fontSize: 22, height: 1.3, fontWeight: FontWeight.bold)),
        if (question['description'] != null && question['description'].toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(question['description'], style: const TextStyle(fontSize: 16, color: Colors.black, height: 1.4)),
        ],
      ],
    );
  }

  /// Delegates to the correct widget based on question type.
  Widget _buildQuestionContent(Map<String, dynamic> question, String type) {
    if (type == GameType.sequenceBuilder) {
      return SequenceBuilderWidget(
        key: ValueKey('seq_${question['id']}'),
        questionData: question,
        onAnswerSubmitted: (score, isCorrect) {
          setState(() {
            _isCardGameComplete = true;
            _gameScores[_currentQuestionIndex] = score;
            _answeredCorrectly[_currentQuestionIndex] = isCorrect;
          });
        },
      );
    }

    if (type == GameType.cardMatch) {
      if (_isFlipCardGame(question)) {
        return SizedBox(
          height: 700,
          child: CardFlipGameWidget(
            key: ValueKey('flip_${question['id']}'),
            pairs: _buildCardPairs(question),
            pointsPerMatch: 10,
            onGameComplete: (score, accuracy) {
              setState(() {
                _isCardGameComplete = true;
                _gameScores[_currentQuestionIndex] = score;
                _answeredCorrectly[_currentQuestionIndex] = accuracy >= 0.7;
              });
            },
            onComplete: (score, accuracy, timeTaken) async {
              await _saveProgress(
                question: question,
                isCorrect: accuracy >= 0.7,
                userAnswer: {'type': GameType.cardMatch, 'score': score, 'accuracy': accuracy},
                pointsEarned: score,
              );
              if (_currentQuestionIndex < _questions.length - 1) {
                setState(() {
                  _currentQuestionIndex++;
                  _currentAttempt = 1;
                  _isCardGameComplete = false;
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
      // Bucket-style card match — handled by CardMatchQuestionWidget
      // (auto-advances via onComplete callback)
      return SizedBox(
        height: 700,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Center(child: Text('Card Match (bucket style) — coming soon')),
        ),
      );
    }

    if (type == GameType.simulation) {
      return SizedBox(
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
      );
    }

    if (type == GameType.matchFollowing) {
      return MatchFollowingWidget(
        question: question,
        userMatches: _matchAnswers[_currentQuestionIndex] ?? {},
        onMatchSelected: (leftItem, value) {
          setState(() {
            _matchAnswers[_currentQuestionIndex] ??= {};
            _matchAnswers[_currentQuestionIndex]![leftItem] = value;
          });
        },
      );
    }

    // MCQ / Scenario / SingleTap
    return McqQuestionWidget(
      question: question,
      selectedIndex: _selectedAnswers[_currentQuestionIndex],
      isLocked: _answeredCorrectly.containsKey(_currentQuestionIndex),
      wasCorrect: _answeredCorrectly[_currentQuestionIndex],
      onOptionSelected: (index) {
        setState(() => _selectedAnswers[_currentQuestionIndex] = index);
      },
    );
  }

  Widget _buildNavigationButtons(bool isAnswered) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentQuestionIndex > 0)
            OutlinedButton(
              onPressed: () {
                setState(() => _currentQuestionIndex--);
                _startQuestionTimer();
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: const Text('Previous'),
            )
          else
            const SizedBox(),
          ElevatedButton(
            onPressed: !isAnswered ? null : _onNextPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(_currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Submit'),
          ),
        ],
      ),
    );
  }

  // ─── RESULTS SCREEN ──────────────────────────────────────

  Widget _buildResultsScreen() {
    final totalQuestions = _questions.length;
    int totalScore = 0;
    int correctAnswers = 0;
    for (int i = 0; i < totalQuestions; i++) {
      final pts = _questionPoints[i] ?? _gameScores[i] ?? 0;
      totalScore += pts;
      if (pts > 0) correctAnswers++;
    }

    final pct = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

    return Stack(children: [
      Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF9E6), Color(0xFFF4EF8B), Color(0xFFE8D96F)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_scoreIcon(pct), size: 100, color: _scoreColor(pct)),
                    const SizedBox(height: 16),
                    Text(_scoreTitle(pct),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    _buildScoreCard(totalScore, correctAnswers, totalQuestions),
                    const SizedBox(height: 32),
                    Text(_encouragement(pct),
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: const Text('Return to Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      CelebrationWidget(show: _showCelebration, onComplete: () => setState(() => _showCelebration = false)),
    ]);
  }

  Widget _buildScoreCard(int score, int correct, int total) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF1A2F4B).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: const Color(0xFFF8C67D).withOpacity(0.5), width: 3),
      ),
      child: Column(children: [
        const Text('YOUR SCORE', style: TextStyle(fontSize: 16, color: Color(0xFF1A2F4B), fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 12),
        Text('$score', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Color(0xFFF08A7E), height: 1)),
        Text('POINTS', style: TextStyle(fontSize: 14, color: const Color(0xFF1A2F4B).withOpacity(0.6), fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF6BCB9F).withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
          child: Text('$correct / $total Correct', style: const TextStyle(fontSize: 18, color: Color(0xFF1A2F4B), fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ─── SCORE HELPERS ───────────────────────────────────────

  IconData _scoreIcon(double pct) {
    if (pct == 100) return Icons.emoji_events_rounded;
    if (pct >= 90) return Icons.star_rounded;
    if (pct >= 70) return Icons.sentiment_very_satisfied_rounded;
    if (pct >= 50) return Icons.thumb_up_rounded;
    return Icons.sentiment_neutral_rounded;
  }

  String _scoreTitle(double pct) {
    if (pct == 100) return 'PERFECT! 🎉';
    if (pct >= 90) return 'AMAZING! ✨';
    if (pct >= 70) return 'GREAT JOB! 🎊';
    if (pct >= 50) return 'GOOD EFFORT! 💫';
    return 'KEEP PRACTICING! 📚';
  }

  String _encouragement(double pct) {
    if (pct == 100) return 'You\'re a quiz master! 🎓';
    if (pct >= 90) return 'Almost perfect! Keep it up! 🚀';
    if (pct >= 70) return 'You\'re doing great! 🌈';
    if (pct >= 50) return 'Nice try! Practice makes perfect! 💡';
    return 'Don\'t give up! You\'ll get better! 🌟';
  }

  Color _scoreColor(double pct) {
    if (pct >= 90) return const Color(0xFFFF6B9D);
    if (pct >= 70) return const Color(0xFF4ECDC4);
    if (pct >= 50) return const Color(0xFF9B59B6);
    return const Color(0xFFFF9A76);
  }
}
