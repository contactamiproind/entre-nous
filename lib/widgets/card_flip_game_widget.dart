import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Card matching game.
///
/// - **Single tap** = peek (card shows briefly, flips back).
/// - **Double-tap** = lock card open permanently.
/// - Two locked cards = match attempt (no right/wrong feedback).
/// - All cards look the same once locked — no green/red cues.
/// - Game ends when all cards are locked.
class CardFlipGameWidget extends StatefulWidget {
  final List<Map<String, dynamic>> pairs;
  final Function(int matchesFound, double accuracy, int timeTaken) onComplete;
  final Function(int matchesFound, double accuracy)? onGameComplete;

  const CardFlipGameWidget({
    super.key,
    required this.pairs,
    required this.onComplete,
    this.onGameComplete,
  });

  @override
  State<CardFlipGameWidget> createState() => _CardFlipGameWidgetState();
}

class _CardFlipGameWidgetState extends State<CardFlipGameWidget>
    with TickerProviderStateMixin {
  List<GameCard> _cards = [];
  int _matchesFound = 0;
  int _lockedCount = 0;
  Timer? _gameTimer;
  int _secondsElapsed = 0;
  bool _isGameComplete = false;
  Timer? _peekTimer;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _peekTimer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    List<GameCard> cards = [];
    int cardId = 0;

    for (var pair in widget.pairs) {
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

    cards.shuffle(Random());
    setState(() => _cards = cards);
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  // ─── SINGLE TAP = PEEK ─────────────────────────────────

  void _onSingleTap(GameCard card) {
    if (_isGameComplete || card.isLocked || card.isPeeking) return;

    // Cancel any existing peek first
    _cancelPeek();

    setState(() => card.isPeeking = true);
    _peekTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => card.isPeeking = false);
    });
  }

  void _cancelPeek() {
    _peekTimer?.cancel();
    for (var c in _cards) {
      if (c.isPeeking) c.isPeeking = false;
    }
  }

  // ─── DOUBLE TAP = LOCK ─────────────────────────────────

  void _onDoubleTap(GameCard card) {
    if (_isGameComplete || card.isLocked) return;

    _peekTimer?.cancel();

    setState(() {
      card.isPeeking = false;
      card.isLocked = true;
      _lockedCount++;
    });

    // Check if two unpaired locked cards exist → form a match attempt
    final unpairedLocked =
        _cards.where((c) => c.isLocked && !c.isPaired).toList();

    if (unpairedLocked.length == 2) {
      final first = unpairedLocked[0];
      final second = unpairedLocked[1];

      first.isPaired = true;
      second.isPaired = true;

      // Silently check correctness — no visual feedback
      if (first.pairId == second.pairId) {
        first.isMatched = true;
        second.isMatched = true;
        _matchesFound++;
      }

      // Game ends when all cards are locked
      if (_lockedCount == _cards.length) {
        _gameComplete();
      }
    }
  }

  void _gameComplete() {
    _gameTimer?.cancel();
    setState(() => _isGameComplete = true);
    final totalPairs = widget.pairs.length;
    final accuracy = totalPairs > 0 ? _matchesFound / totalPairs : 0.0;
    widget.onGameComplete?.call(_matchesFound, accuracy);
  }

  void completeGame() {
    if (_isGameComplete) {
      final totalPairs = widget.pairs.length;
      final accuracy = totalPairs > 0 ? _matchesFound / totalPairs : 0.0;
      widget.onComplete(_matchesFound, accuracy, _secondsElapsed);
    }
  }

  // ─── BUILD ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gridSize = _calculateGridSize(_cards.length);

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Hint text
          if (!_isGameComplete) ...[
            Text(
              'Tap to peek  •  Double-tap to lock',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Card Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize.columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) => _buildCard(_cards[index]),
          ),

          if (_isGameComplete) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EF8B).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF1E293B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'All cards locked! Tap Next to see results.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── CARD WIDGET ───────────────────────────────────────

  Widget _buildCard(GameCard card) {
    final bool showFace = card.isPeeking || card.isLocked;

    return GestureDetector(
      onTap: () => _onSingleTap(card),
      onDoubleTap: () => _onDoubleTap(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          // No green — locked cards look the same as peeked cards (white)
          color: showFace ? Colors.white : const Color(0xFFF4EF8B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: card.isLocked
                ? const Color(0xFFE8D96F)
                : showFace
                    ? const Color(0xFFE8D96F).withOpacity(0.5)
                    : Colors.transparent,
            width: card.isLocked ? 3 : 2,
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
          child: showFace
              ? _buildCardContent(card)
              : const Icon(Icons.question_mark, size: 40, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildCardContent(GameCard card) {
    if (card.icon != null && card.icon!.isNotEmpty) {
      return Text(card.icon!, style: const TextStyle(fontSize: 36));
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              card.content,
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GridSize _calculateGridSize(int cardCount) {
    if (cardCount <= 4) return GridSize(2, 2);
    if (cardCount <= 6) return GridSize(3, 2);
    if (cardCount <= 8) return GridSize(4, 2);
    if (cardCount <= 12) return GridSize(4, 3);
    if (cardCount <= 16) return GridSize(4, 4);
    return GridSize(5, 4);
  }
}

class GameCard {
  final int id;
  final int pairId;
  final String content;
  final String? icon;
  bool isPeeking;
  bool isLocked;
  bool isPaired;
  bool isMatched;

  GameCard({
    required this.id,
    required this.pairId,
    required this.content,
    this.icon,
    this.isPeeking = false,
    this.isLocked = false,
    this.isPaired = false,
    this.isMatched = false,
  });
}

class GridSize {
  final int columns;
  final int rows;

  GridSize(this.columns, this.rows);
}
