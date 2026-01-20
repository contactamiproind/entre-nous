import 'package:flutter/material.dart';
import '../widgets/card_flip_game_widget.dart';

/// Demo screen to test the Card Flip Memory Match game
class CardFlipGameDemo extends StatelessWidget {
  const CardFlipGameDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample pairs for testing
    final samplePairs = [
      {'id': 1, 'left': '🍎', 'right': 'Apple', 'left_icon': '🍎', 'right_icon': null},
      {'id': 2, 'left': '🍌', 'right': 'Banana', 'left_icon': '🍌', 'right_icon': null},
      {'id': 3, 'left': '🍊', 'right': 'Orange', 'left_icon': '🍊', 'right_icon': null},
      {'id': 4, 'left': '🍇', 'right': 'Grapes', 'left_icon': '🍇', 'right_icon': null},
      {'id': 5, 'left': '🍓', 'right': 'Strawberry', 'left_icon': '🍓', 'right_icon': null},
      {'id': 6, 'left': '🍉', 'right': 'Watermelon', 'left_icon': '🍉', 'right_icon': null},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Flip Memory Match'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
      body: CardFlipGameWidget(
        pairs: samplePairs,
        pointsPerMatch: 10,
        onComplete: (score, accuracy, timeTaken) {
          // Show completion dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.celebration, color: Color(0xFFFBBF24), size: 32),
                  SizedBox(width: 12),
                  Text('Game Complete!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Final Score: $score points',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${timeTaken ~/ 60}:${(timeTaken % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Reload the page to restart
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const CardFlipGameDemo()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Play Again'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
