import 'package:flutter/material.dart';

/// Callback when user selects an option.
typedef OnOptionSelected = void Function(int index);

/// Reusable Multiple Choice / Scenario Decision question renderer.
/// Displays options as tappable cards with letter badges (A, B, C, D).
/// Shows correct/wrong feedback when locked.
class McqQuestionWidget extends StatelessWidget {
  /// The question data map containing 'options' and 'options_data'.
  final Map<String, dynamic> question;

  /// Currently selected option index (null if none selected).
  final int? selectedIndex;

  /// Whether this question has been answered (locked for further input).
  final bool isLocked;

  /// Whether the locked answer was correct.
  final bool? wasCorrect;

  /// Called when user taps an option.
  final OnOptionSelected onOptionSelected;

  /// Theme colors for option cards.
  static const List<Color> optionColors = [
    Color(0xFFF08A7E), // Coral
    Color(0xFF6BCB9F), // Teal
    Color(0xFFF8C67D), // Yellow
    Color(0xFF74C0D9), // Light Blue
  ];

  const McqQuestionWidget({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.isLocked,
    this.wasCorrect,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> options = question['options'] ?? [];
    final List<dynamic> optionsData = question['options_data'] ?? [];

    if (options.isEmpty) {
      return const Center(child: Text('No options available'));
    }

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final optionColor = optionColors[index % optionColors.length];
        final isSelected = selectedIndex == index;

        // Feedback colors only when locked
        final bool isCorrectOption = isLocked &&
            index < optionsData.length &&
            optionsData[index]['is_correct'] == true;
        final bool isWrongSelection =
            isLocked && isSelected && wasCorrect == false;

        // Determine card state
        Color bgColor;
        Color borderColor;
        Color textColor;
        Widget? trailing;

        if (isCorrectOption) {
          bgColor = const Color(0xFFE8F8F0);
          borderColor = const Color(0xFF6BCB9F);
          textColor = const Color(0xFF1A2F4B);
          trailing = const Icon(Icons.check_circle_rounded,
              color: Color(0xFF6BCB9F), size: 24);
        } else if (isWrongSelection) {
          bgColor = const Color(0xFFFDE8E4);
          borderColor = const Color(0xFFF08A7E);
          textColor = const Color(0xFF1A2F4B);
          trailing = const Icon(Icons.cancel_rounded,
              color: Color(0xFFF08A7E), size: 24);
        } else if (isSelected && !isLocked) {
          bgColor = optionColor;
          borderColor = optionColor;
          textColor = Colors.white;
          trailing = const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 24);
        } else {
          bgColor = Colors.white;
          borderColor = Colors.grey.shade300;
          textColor = const Color(0xFF1A2F4B);
          trailing = null;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLocked ? null : () => onOptionSelected(index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(
                    color: borderColor,
                    width: (isSelected || isCorrectOption || isWrongSelection)
                        ? 2.5
                        : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected && !isLocked
                            ? Colors.white.withOpacity(0.25)
                            : optionColor.withOpacity(0.12),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected && !isLocked
                                ? Colors.white
                                : optionColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: textColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
