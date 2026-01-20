import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

class CardMatchQuestionWidget extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final Function(int score, bool isCorrect) onAnswerSubmitted;

  const CardMatchQuestionWidget({
    super.key,
    required this.questionData,
    required this.onAnswerSubmitted,
  });

  @override
  State<CardMatchQuestionWidget> createState() => _CardMatchQuestionWidgetState();
}

class _CardMatchQuestionWidgetState extends State<CardMatchQuestionWidget> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> options;
  late List<Map<String, dynamic>> buckets;
  late List<Map<String, dynamic>> cards;
  
  Map<String, String?> cardPlacements = {}; // cardId -> bucketId
  Set<String> lockedCards = {};
  String? shakingCardId;
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
      debugPrint('🎮 CardMatchQuestionWidget._initializeGame()');
      debugPrint('   Options type: ${widget.questionData['options'].runtimeType}');
      debugPrint('   Options value: ${widget.questionData['options']}');
      
      // Parse options - handle both String (JSON) and Map formats
      if (widget.questionData['options'] == null) {
        debugPrint('ERROR: Card Match question has null options');
        options = {'buckets': [], 'cards': []};
      } else if (widget.questionData['options'] is String) {
        debugPrint('   Parsing options from JSON string');
        options = jsonDecode(widget.questionData['options']);
      } else if (widget.questionData['options'] is Map) {
        debugPrint('   Converting options from Map');
        options = Map<String, dynamic>.from(widget.questionData['options']);
      } else {
        debugPrint('ERROR: Unexpected options type: ${widget.questionData['options'].runtimeType}');
        debugPrint('ERROR: Options value: ${widget.questionData['options']}');
        options = {'buckets': [], 'cards': []};
      }
      
      // Validate and extract buckets
      if (options['buckets'] != null && options['buckets'] is List) {
        buckets = List<Map<String, dynamic>>.from(options['buckets']);
      } else {
        debugPrint('ERROR: Invalid or missing buckets in Card Match question');
        buckets = [];
      }
      
      // Validate and extract cards
      if (options['cards'] != null && options['cards'] is List) {
        cards = List<Map<String, dynamic>>.from(options['cards']);
      } else {
        debugPrint('ERROR: Invalid or missing cards in Card Match question');
        cards = [];
      }
      
      debugPrint('Card Match initialized: ${buckets.length} buckets, ${cards.length} cards');
      
    } catch (e, stackTrace) {
      debugPrint('ERROR initializing Card Match game: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Question data: ${widget.questionData}');
      
      // Fallback to empty data to prevent crash
      options = {'buckets': [], 'cards': []};
      buckets = [];
      cards = [];
    }
    
    // Shuffle cards
    cards.shuffle(Random());
    
    // Initialize placements
    for (var card in cards) {
      cardPlacements[card['id']] = null;
    }
  }

  void _onCardDropped(String cardId, String bucketId) {
    final card = cards.firstWhere((c) => c['id'] == cardId);
    final correctBucket = card['correct_bucket'];

    if (correctBucket == bucketId) {
      // Correct match
      setState(() {
        cardPlacements[cardId] = bucketId;
        lockedCards.add(cardId);
        score += 10;
        correctMatches++;
      });

      // Check if all cards are matched
      if (correctMatches == cards.length) {
        score += 20; // Completion bonus
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onAnswerSubmitted(score, true);
        });
      }
    } else {
      // Wrong match
      setState(() {
        shakingCardId = cardId;
      });
      
      _shakeController.forward().then((_) {
        _shakeController.reverse().then((_) {
          setState(() {
            shakingCardId = null;
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
    return Column(
      children: [
        // Question Text
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.questionData['question_text'] ?? 'Match the cards to the correct buckets',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
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
                  color: Color(0xFFE8D96F),
                ),
              ),
              Text(
                'Matched: $correctMatches/${cards.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Buckets
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: buckets.map((bucket) => Flexible(
              fit: FlexFit.tight,
              child: _buildBucket(bucket),
            )).toList(),
          ),
        ),
        
        // Cards
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final cardId = card['id'];
                
                if (lockedCards.contains(cardId)) {
                  return const SizedBox.shrink();
                }
                
                return _buildDraggableCard(card);
              },
            ),
          ),
        ),
        
        // Hint
        if (shakingCardId != null)
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
                      'Think: Does this reduce effort or create emotion?',
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

  Widget _buildBucket(Map<String, dynamic> bucket) {
    final bucketId = bucket['id'];
    final label = bucket['label'];
    final color = _getBucketColor(bucket['color'] ?? bucket['id']);
    final icon = _getBucketIcon(bucket['icon'] ?? bucket['id']);
    
    final cardsInBucket = cardPlacements.entries
        .where((e) => e.value == bucketId)
        .map((e) => e.key)
        .toList();

    return DragTarget<String>(
      onAccept: (cardId) => _onCardDropped(cardId, bucketId),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHovering ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovering ? color : color.withOpacity(0.3),
              width: isHovering ? 3 : 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              ...cardsInBucket.map((cardId) {
                final card = cards.firstWhere((c) => c['id'] == cardId);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          card['text'],
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableCard(Map<String, dynamic> card) {
    final cardId = card['id'];
    final isShaking = shakingCardId == cardId;
    
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
      child: Draggable<String>(
        data: cardId,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8D96F), width: 2),
            ),
            child: Text(
              card['text'],
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildCardContent(card),
        ),
        child: _buildCardContent(card, isShaking: isShaking),
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> card, {bool isShaking = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isShaking ? Colors.red : const Color(0xFFE5E7EB),
          width: isShaking ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isShaking ? Colors.red.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          card['text'],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _getBucketColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
      case 'ease':
        return const Color(0xFFE8D96F);
      case 'gold':
      case 'yellow':
      case 'delight':
        return const Color(0xFFF4EF8B);
      default:
        return Colors.grey;
    }
  }

  IconData _getBucketIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'checklist':
      case 'ease':
        return Icons.checklist;
      case 'star':
      case 'delight':
        return Icons.star;
      default:
        return Icons.category;
    }
  }
}
