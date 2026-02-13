import 'package:flutter/material.dart';

/// Callback when user selects a match for a left item.
typedef OnMatchSelected = void Function(String leftItem, String? rightValue);

/// Reusable Match the Following question renderer.
/// Displays left items with dropdown selectors for right items.
class MatchFollowingWidget extends StatelessWidget {
  /// The question data map containing 'match_pairs'.
  final Map<String, dynamic> question;

  /// Current user matches: {leftItem -> "rightValue|index"}.
  final Map<String, String?> userMatches;

  /// Called when user selects a match.
  final OnMatchSelected onMatchSelected;

  /// Theme colors for pair cards.
  static const List<Color> pairColors = [
    Color(0xFFF08A7E), // Coral
    Color(0xFF6BCB9F), // Teal
    Color(0xFFF8C67D), // Yellow
    Color(0xFF74C0D9), // Light Blue
    Color(0xFF95E1D3), // Mint
    Color(0xFFFF9A76), // Orange
  ];

  const MatchFollowingWidget({
    super.key,
    required this.question,
    required this.userMatches,
    required this.onMatchSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pairs =
        List<Map<String, dynamic>>.from(question['match_pairs'] ?? []);

    // Create unique right items with index to avoid duplicate dropdown values
    final rightItemsWithIndex = pairs.asMap().entries.map((entry) {
      return '${entry.value['right']}|${entry.key}';
    }).toList();

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                              color: Color(0xFF1A2F4B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child:
                        Icon(Icons.arrow_downward_rounded, color: Colors.grey),
                  ),

                  // Right Item Dropdown (Answer)
                  Container(
                    decoration: BoxDecoration(
                      color: selectedRight != null
                          ? pairColor.withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            selectedRight != null ? pairColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedRight,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: 'Select Match',
                        hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        prefixIcon: Icon(
                          selectedRight != null ? Icons.link : Icons.link_off,
                          color: selectedRight != null
                              ? pairColor
                              : Colors.grey[400],
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1A2F4B),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        onMatchSelected(leftItem, value);
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
}
