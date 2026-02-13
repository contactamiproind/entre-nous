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
  bool _showResults = false;
  bool _showCelebration = false;

  // Per-question state
  final Map<int, int> _selectedAnswers = {};
  final Map<int, bool> _answeredCorrectly = {};
  Map<int, Map<String, String?>> _matchAnswers = {};
  /// Single source of truth for points earned per question index.
  /// Correct → question['points'], Wrong → 0. No complex logic.
  final Map<int, int> _questionPoints = {};

  // Timer
  Timer? _questionTimer;
  int _remainingSeconds = 30;
  int _questionTimeLimit = 30;

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
  // Simple rule: correct → full points from question, wrong → 0.

  /// Returns the points value defined on the question.
  int _getQuestionPoints(int qi) {
    if (qi >= 0 && qi < _questions.length) {
      return (_questions[qi]['points'] as int?) ?? 10;
    }
    return 10;
  }

  /// Record score: correct = question's points, wrong = 0.
  void _recordScore(int qi, bool isCorrect) {
    _questionPoints[qi] = isCorrect ? _getQuestionPoints(qi) : 0;
    _answeredCorrectly[qi] = isCorrect;
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
    final int correctCount =
        _answeredCorrectly.values.where((v) => v == true).length;
    final percentage =
        _questions.isEmpty ? 0.0 : (correctCount / _questions.length) * 100;

    setState(() {
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
      final points = _getQuestionPoints(_currentQuestionIndex);
      _recordScore(_currentQuestionIndex, true);

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
        _recordScore(_currentQuestionIndex, false);

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
    final points = allCorrect ? _getQuestionPoints(_currentQuestionIndex) : 0;

    _questionTimer?.cancel();
    _recordScore(_currentQuestionIndex, allCorrect);

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
    final isCorrect = _answeredCorrectly[_currentQuestionIndex] ?? false;
    _questionTimer?.cancel();

    // Card match scoring is already set per-match by onGameComplete — don't overwrite
    if (type != GameType.cardMatch) {
      _recordScore(_currentQuestionIndex, isCorrect);
    }
    final score = _questionPoints[_currentQuestionIndex] ?? 0;
    final maxPts = _getQuestionPoints(_currentQuestionIndex);
    final isPartial = type == GameType.cardMatch && score > 0 && score < maxPts;

    await _saveProgress(
      question: question,
      isCorrect: isCorrect,
      userAnswer: {'type': type, 'score': score, 'time_taken': _questionTimeLimit - _remainingSeconds},
      pointsEarned: score,
    );

    _showCelebrationThenAdvance(score, isPartial: isPartial);
  }

  void _showCelebrationThenAdvance(int points, {bool isPartial = false}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final bool hasPoints = points > 0;

    // Determine title and message
    String title;
    String message;
    if (hasPoints && !isPartial) {
      title = 'Well Done!';
      message = 'Great job! Keep it up!';
    } else if (hasPoints && isPartial) {
      title = 'Good Try!';
      message = 'You got some right!';
    } else {
      title = 'Wrong Answer';
      message = 'Better luck on the next one!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: hasPoints ? const Color(0xFFFFF9E6) : Colors.white,
        title: Row(
          children: [
            Icon(
              hasPoints ? Icons.celebration_rounded : Icons.sentiment_dissatisfied_rounded,
              color: hasPoints ? const Color(0xFFE8D96F) : const Color(0xFFF08A7E),
              size: 32,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: hasPoints ? const Color(0xFF1E293B) : const Color(0xFFF08A7E),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _advanceToNext();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPoints ? const Color(0xFFF4EF8B) : const Color(0xFF8B5CF6),
              foregroundColor: hasPoints ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
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
    // Card match uses options as a list of pair objects, or match_pairs
    final options = question['options'];
    final matchPairs = question['match_pairs'];
    debugPrint('🃏 _isFlipCardGame check: options=${options?.runtimeType}, match_pairs=${matchPairs?.runtimeType}');
    if (options is List && options.isNotEmpty && options[0] is Map) {
      final first = options[0] as Map;
      debugPrint('🃏   options[0] keys: ${first.keys.toList()}');
      // Support both key formats: question/answer OR left/right
      return (first.containsKey('question') && first.containsKey('answer')) ||
             (first.containsKey('left') && first.containsKey('right'));
    }
    if (matchPairs is List && matchPairs.isNotEmpty) {
      debugPrint('🃏   Using match_pairs instead');
      return true;
    }
    return false;
  }

  List<Map<String, dynamic>> _buildCardPairs(Map<String, dynamic> question) {
    // Try options first, then match_pairs
    var rawPairs = question['options'];
    if (rawPairs == null || rawPairs is! List || rawPairs.isEmpty) {
      rawPairs = question['match_pairs'];
    }
    if (rawPairs == null || rawPairs is! List) return [];

    return rawPairs.asMap().entries
        .map<Map<String, dynamic>>((entry) {
          final p = entry.value;
          if (p is! Map) return <String, dynamic>{};
          return {
            'id': p['id'] ?? entry.key,
            'left': p['question'] ?? p['left'] ?? '',
            'right': p['answer'] ?? p['right'] ?? '',
            'left_icon': null,
            'right_icon': null,
          };
        })
        .where((p) => p.isNotEmpty)
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
            _answeredCorrectly[_currentQuestionIndex] = isCorrect;
          });
        },
      );
    }

    if (type == GameType.cardMatch) {
      if (_isFlipCardGame(question)) {
        final cardPairs = _buildCardPairs(question);
        return SizedBox(
          height: 700,
          child: CardFlipGameWidget(
            key: ValueKey('flip_${question['id']}'),
            pairs: cardPairs,
            onGameComplete: (matchesFound, accuracy) {
              // Distribute total points among correct matches
              final totalPts = (question['points'] as int?) ?? 10;
              final pairCount = cardPairs.length;
              final perMatch = pairCount > 0 ? totalPts / pairCount : 0.0;
              final earnedPts = (perMatch * matchesFound).round();
              debugPrint('🎯 CardMatch onGameComplete: totalPts=$totalPts, pairs=$pairCount, matched=$matchesFound, earned=$earnedPts');
              setState(() {
                _isCardGameComplete = true;
                _questionPoints[_currentQuestionIndex] = earnedPts;
                _answeredCorrectly[_currentQuestionIndex] = matchesFound == pairCount;
              });
            },
            onComplete: (matchesFound, accuracy, timeTaken) async {
              final earnedPts = _questionPoints[_currentQuestionIndex] ?? 0;
              final allCorrect = matchesFound == cardPairs.length;
              await _saveProgress(
                question: question,
                isCorrect: allCorrect,
                userAnswer: {'type': GameType.cardMatch, 'matches': matchesFound, 'total_pairs': cardPairs.length, 'score': earnedPts},
                pointsEarned: earnedPts,
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
    int maxPossible = 0;

    for (int i = 0; i < totalQuestions; i++) {
      final pts = _questionPoints[i] ?? 0;
      final qPts = (_questions[i]['points'] as int?) ?? 10;
      totalScore += pts;
      maxPossible += qPts;
      if (pts > 0) correctAnswers++;
    }

    final pct = totalQuestions > 0
        ? (correctAnswers / totalQuestions) * 100
        : 0.0;
    final scorePct = maxPossible > 0
        ? (totalScore / maxPossible)
        : 0.0;

    // Tier
    final String title;
    final String subtitle;
    final IconData icon;
    final Color accentColor;

    if (pct == 100) {
      title = 'PERFECT!';
      subtitle = 'You nailed every single question!';
      icon = Icons.emoji_events_rounded;
      accentColor = const Color(0xFFFFD700);
    } else if (pct >= 70) {
      title = 'GREAT JOB!';
      subtitle = 'You\'re doing amazing!';
      icon = Icons.star_rounded;
      accentColor = const Color(0xFF4ECDC4);
    } else if (pct >= 50) {
      title = 'GOOD EFFORT!';
      subtitle = 'Keep practicing to improve!';
      icon = Icons.thumb_up_rounded;
      accentColor = const Color(0xFF9B59B6);
    } else {
      title = 'KEEP GOING!';
      subtitle = 'Every attempt makes you better!';
      icon = Icons.refresh_rounded;
      accentColor = const Color(0xFFFF9A76);
    }

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Trophy / Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 56, color: accentColor),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(title,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center),

                  const SizedBox(height: 28),

                  // ── Score Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(children: [
                      // Score circle
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: CircularProgressIndicator(
                                value: scorePct,
                                strokeWidth: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$totalScore',
                                    style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: accentColor,
                                        height: 1)),
                                Text('/ $maxPossible',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Stats row
                      Row(
                        children: [
                          _buildResultStat(
                            Icons.check_circle_outline,
                            'Correct',
                            '$correctAnswers / $totalQuestions',
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 12),
                          _buildResultStat(
                            Icons.close_rounded,
                            'Wrong',
                            '${totalQuestions - correctAnswers} / $totalQuestions',
                            const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 12),
                          _buildResultStat(
                            Icons.star_outline_rounded,
                            'Points',
                            '$totalScore',
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // ── Per-question breakdown ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Question Breakdown',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B))),
                        const SizedBox(height: 12),
                        ...List.generate(totalQuestions, (i) {
                          final q = _questions[i];
                          final earned = _questionPoints[i] ?? 0;
                          final max = (q['points'] as int?) ?? 10;
                          final correct = earned > 0;
                          final qTitle = (q['title'] as String?) ?? 'Question ${i + 1}';
                          final displayTitle = qTitle.length > 40
                              ? '${qTitle.substring(0, 40)}...'
                              : qTitle;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                // Status icon
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: correct
                                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    correct ? Icons.check : Icons.close,
                                    size: 16,
                                    color: correct
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Question title
                                Expanded(
                                  child: Text(displayTitle,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                // Points
                                Text('$earned / $max',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: correct
                                            ? const Color(0xFF10B981)
                                            : Colors.grey[400])),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Return button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Return to Dashboard',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      CelebrationWidget(
          show: _showCelebration,
          onComplete: () => setState(() => _showCelebration = false)),
    ]);
  }

  Widget _buildResultStat(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
