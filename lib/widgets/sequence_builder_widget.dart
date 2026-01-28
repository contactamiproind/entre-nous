import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

class SequenceBuilderWidget extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final Function(int score, bool isCorrect) onAnswerSubmitted;

  const SequenceBuilderWidget({
    super.key,
    required this.questionData,
    required this.onAnswerSubmitted,
  });

  @override
  State<SequenceBuilderWidget> createState() => _SequenceBuilderWidgetState();
}

class _SequenceBuilderWidgetState extends State<SequenceBuilderWidget> with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> sentences;
  Map<int, int?> sentencePlacements = {}; // sentenceId -> placed number
  Set<int> usedNumbers = {};
  Set<int> lockedSentences = {};
  int? shakingSentenceId;
  int score = 0;
  int correctMatches = 0;
  
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _initializeGame() {
    try {
      // Reset game state
      usedNumbers.clear();
      lockedSentences.clear();
      sentencePlacements.clear();
      score = 0;
      correctMatches = 0;
      shakingSentenceId = null;
      
      debugPrint('🎮 SequenceBuilderWidget._initializeGame()');
      debugPrint('   Options type: ${widget.questionData['options'].runtimeType}');
      debugPrint('   Options value: ${widget.questionData['options']}');
      
      // Parse options - handle both String (JSON) and List formats
      List<dynamic> optionsRaw;
      if (widget.questionData['options'] == null) {
        debugPrint('ERROR: Sequence Builder question has null options');
        sentences = [];
        return;
      } else if (widget.questionData['options'] is String) {
        debugPrint('   Parsing options from JSON string');
        optionsRaw = jsonDecode(widget.questionData['options']);
      } else if (widget.questionData['options'] is List) {
        debugPrint('   Converting options from List');
        optionsRaw = widget.questionData['options'];
      } else {
        debugPrint('ERROR: Unexpected options type: ${widget.questionData['options'].runtimeType}');
        sentences = [];
        return;
      }
      
      // Convert to list of sentence maps
      sentences = optionsRaw.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
      
      debugPrint('Sequence Builder initialized: ${sentences.length} sentences');
      
      // Initialize placements
      for (var sentence in sentences) {
        sentencePlacements[sentence['id']] = null;
      }
      
    } catch (e, stackTrace) {
      debugPrint('ERROR initializing Sequence Builder game: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Question data: ${widget.questionData}');
      sentences = [];
    }
  }

  @override
  void didUpdateWidget(SequenceBuilderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize if data changes (though Key in parent should handle this, this is a safety fallback)
    if (widget.questionData['id'] != oldWidget.questionData['id']) {
      _initializeGame();
    }
  }

  void _onNumberDropped(int number, int sentenceId) {
    final sentence = sentences.firstWhere((s) => s['id'] == sentenceId);
    final correctPosition = sentence['correct_position'];

    if (correctPosition == number) {
      // Correct match
      setState(() {
        sentencePlacements[sentenceId] = number;
        usedNumbers.add(number);
        lockedSentences.add(sentenceId);
        score += 10;
        correctMatches++;
      });

      // Check if all sentences are matched
      if (correctMatches == sentences.length) {
        score += 20; // Completion bonus
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onAnswerSubmitted(score, true);
        });
      }
    } else {
      // Wrong match
      setState(() {
        shakingSentenceId = sentenceId;
      });
      
      _shakeController.forward().then((_) {
        _shakeController.reverse().then((_) {
          setState(() {
            shakingSentenceId = null;
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error if no sentences loaded
    if (sentences.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading sequence builder question',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Options data: ${widget.questionData['options']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Title removed (handled by parent screen)
        

        // Score Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score: $score',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                'Matched: $correctMatches/${sentences.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Draggable Numbers Area
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive size based on screen width
            final screenWidth = constraints.maxWidth;
            final boxSize = (screenWidth / 5.5).clamp(55.0, 75.0);
            final fontSize = (boxSize * 0.6).clamp(28.0, 40.0);
            
            debugPrint('📦 Draggable area - screenWidth: $screenWidth, boxSize: $boxSize, fontSize: $fontSize');
            debugPrint('📦 Number of sentences: ${sentences.length}');
            
            return Container(
              constraints: BoxConstraints(
                minHeight: boxSize + 30,
                maxHeight: boxSize * 2.5, // Allow wrapping to multiple rows
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6), // Light yellow background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8D96F), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(sentences.length, (index) {
                  final number = index + 1;
                  final isUsed = usedNumbers.contains(number);
                  
                  if (isUsed) {
                    return const SizedBox.shrink();
                  }
                  
                  return Draggable<int>(
                    data: number,
                    feedback: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.orange.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                        child: Center(
                          child: OverflowBox(
                            minWidth: 0,
                            maxWidth: double.infinity,
                            minHeight: 0,
                            maxHeight: double.infinity,
                            child: Text(
                              number.toString(),
                              style: TextStyle(
                                fontSize: boxSize * 0.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                                fontFamily: 'Roboto',
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildNumberBox(number, boxSize, fontSize),
                    ),
                    child: _buildNumberBox(number, boxSize, fontSize),
                  );
                }),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Sentences with Drop Zones
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive size based on screen width
              final screenWidth = constraints.maxWidth;
              final boxSize = (screenWidth / 6.0).clamp(50.0, 70.0);
              final fontSize = (boxSize * 0.55).clamp(24.0, 35.0);
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: sentences.length,
                itemBuilder: (context, index) {
                  final sentence = sentences[index];
                  final sentenceId = sentence['id'];
                  final isLocked = lockedSentences.contains(sentenceId);
                  final isShaking = shakingSentenceId == sentenceId;
                  
                  return AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final offset = isShaking
                          ? sin(_shakeController.value * pi * 4) * 10
                          : 0.0;
                      
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.green.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isShaking 
                              ? Colors.red 
                              : isLocked 
                                  ? Colors.green 
                                  : const Color(0xFFE5E7EB),
                          width: isShaking || isLocked ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isShaking 
                                ? Colors.red.withOpacity(0.3) 
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Drop Zone for Number
                          DragTarget<int>(
                            onAccept: (number) => _onNumberDropped(number, sentenceId),
                            builder: (context, candidateData, rejectedData) {
                              final isHovering = candidateData.isNotEmpty;
                              final placedNumber = sentencePlacements[sentenceId];
                              
                              return Container(
                                width: boxSize,
                                height: boxSize,
                                decoration: BoxDecoration(
                                  color: isLocked
                                      ? Colors.green
                                      : isHovering
                                          ? const Color(0xFFE8D96F).withOpacity(0.5)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isLocked
                                        ? Colors.green
                                        : isHovering
                                            ? const Color(0xFFE8D96F)
                                            : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: placedNumber != null
                                      ? Text(
                                          placedNumber.toString(),
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                            color: isLocked ? Colors.white : Colors.black,
                                          ),
                                        )
                                      : Icon(
                                          Icons.add,
                                          color: Colors.grey.shade400,
                                          size: boxSize * 0.5,
                                        ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Sentence Text
                          Expanded(
                            child: Text(
                              sentence['text'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isLocked ? FontWeight.w600 : FontWeight.normal,
                                color: isLocked ? Colors.green.shade900 : Colors.black,
                              ),
                            ),
                          ),
                          
                          // Check Icon for Locked
                          if (isLocked)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Hint
        if (shakingSentenceId != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Try a different number! Think about the correct sequence.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNumberBox(int number, double boxSize, double fontSize) {
    debugPrint('🔢 Building number box for: $number, size: $boxSize, fontSize: $fontSize');
    
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: boxSize * 0.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration: TextDecoration.none,
              fontFamily: 'Roboto',
              shadows: const [
                Shadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
