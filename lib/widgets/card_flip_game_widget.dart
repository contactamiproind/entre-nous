import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class CardFlipGameWidget extends StatefulWidget {
  final List<Map<String, dynamic>> pairs;
  final Function(int score, double accuracy, int timeTaken) onComplete;
  final int pointsPerMatch;

  const CardFlipGameWidget({
    super.key,
    required this.pairs,
    required this.onComplete,
    this.pointsPerMatch = 10,
  });

  @override
  State<CardFlipGameWidget> createState() => _CardFlipGameWidgetState();
}

class _CardFlipGameWidgetState extends State<CardFlipGameWidget> with TickerProviderStateMixin {
  List<GameCard> _cards = [];
  GameCard? _firstFlipped;
  GameCard? _secondFlipped;
  bool _isProcessing = false;
  int _matchesFound = 0;
  int _totalAttempts = 0;
  int _score = 0;
  Timer? _gameTimer;
  int _secondsElapsed = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
  
  void _initializeGame() {
    debugPrint('🎮 CardFlipGameWidget._initializeGame()');
    debugPrint('   Pairs received: ${widget.pairs.length}');
    debugPrint('   Pairs data: ${widget.pairs}');
    
    // Create cards from pairs
    List<GameCard> cards = [];
    int cardId = 0;
    
    for (var pair in widget.pairs) {
      debugPrint('   Processing pair ${pair['id']}: left="${pair['left']}", right="${pair['right']}"');
      
      // Each pair creates 2 cards
      cards.add(GameCard(
        id: cardId++,
        pairId: pair['id'] ?? cardId ~/ 2,
        content: pair['left'] ?? '',
        icon: pair['left_icon'],
      ));
      cards.add(GameCard(
        id: cardId++,
        pairId: pair['id'] ?? cardId ~/ 2,
        content: pair['right'] ?? '',
        icon: pair['right_icon'],
      ));
    }
    
    // Shuffle cards
    cards.shuffle(Random());
    
    debugPrint('   Created ${cards.length} cards total');
    
    setState(() {
      _cards = cards;
    });
    
    debugPrint('   ✅ Game initialized with ${_cards.length} cards');
  }
  
  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }
  
  void _onCardTap(GameCard card) {
    if (_isProcessing || card.isMatched || card.isFlipped) return;
    
    setState(() {
      card.isFlipped = true;
    });
    
    if (_firstFlipped == null) {
      _firstFlipped = card;
    } else if (_secondFlipped == null) {
      _secondFlipped = card;
      _totalAttempts++;
      _checkMatch();
    }
  }
  
  void _checkMatch() {
    _isProcessing = true;
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_firstFlipped!.pairId == _secondFlipped!.pairId) {
        // Match found!
        setState(() {
          _firstFlipped!.isMatched = true;
          _secondFlipped!.isMatched = true;
          _matchesFound++;
          _score += widget.pointsPerMatch;
        });
        
        // Check if game is complete
        if (_matchesFound == widget.pairs.length) {
          _gameComplete();
        }
      } else {
        // No match - flip back
        setState(() {
          _firstFlipped!.isFlipped = false;
          _secondFlipped!.isFlipped = false;
        });
      }
      
      setState(() {
        _firstFlipped = null;
        _secondFlipped = null;
        _isProcessing = false;
      });
    });
  }
  
  void _gameComplete() {
    _gameTimer?.cancel();
    final accuracy = _matchesFound / _totalAttempts;
    widget.onComplete(_score, accuracy, _secondsElapsed);
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 CardFlipGameWidget.build() called');
    debugPrint('   Cards count: ${_cards.length}');
    debugPrint('   Matches found: $_matchesFound / ${widget.pairs.length}');
    
    final gridSize = _calculateGridSize(_cards.length);
    
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Score and Timer Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFBBF24), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Score: $_score',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                // Timer removed - using main quiz timer instead
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Matches Counter
          Text(
            'Matches: $_matchesFound/${widget.pairs.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Card Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize.columns,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                return _buildCard(_cards[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCard(GameCard card) {
    return GestureDetector(
      onTap: () => _onCardTap(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: card.isMatched
              ? const Color(0xFF6BCB9F).withOpacity(0.3)
              : card.isFlipped
                  ? Colors.white
                  : const Color(0xFF8B5CF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: card.isMatched
                ? const Color(0xFF6BCB9F)
                : card.isFlipped
                    ? const Color(0xFF8B5CF6)
                    : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: card.isFlipped || card.isMatched
              ? _buildCardContent(card)
              : const Icon(
                  Icons.question_mark,
                  size: 40,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
  
  Widget _buildCardContent(GameCard card) {
    if (card.icon != null && card.icon!.isNotEmpty) {
      // Try to parse as emoji or icon
      return Text(
        card.icon!,
        style: const TextStyle(fontSize: 40),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        card.content,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
  
  GridSize _calculateGridSize(int cardCount) {
    // Calculate optimal grid dimensions
    if (cardCount <= 4) return GridSize(2, 2);
    if (cardCount <= 6) return GridSize(2, 3);
    if (cardCount <= 8) return GridSize(2, 4);
    if (cardCount <= 12) return GridSize(3, 4);
    if (cardCount <= 16) return GridSize(4, 4);
    return GridSize(4, 5);
  }
}

class GameCard {
  final int id;
  final int pairId;
  final String content;
  final String? icon;
  bool isFlipped;
  bool isMatched;
  
  GameCard({
    required this.id,
    required this.pairId,
    required this.content,
    this.icon,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class GridSize {
  final int columns;
  final int rows;
  
  GridSize(this.columns, this.rows);
}
