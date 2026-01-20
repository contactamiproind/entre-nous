import 'package:flutter/material.dart';
import 'dart:convert';

class ScenarioDecisionWidget extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final Function(int score, bool isCorrect) onAnswerSubmitted;

  const ScenarioDecisionWidget({
    super.key,
    required this.questionData,
    required this.onAnswerSubmitted,
  });

  @override
  State<ScenarioDecisionWidget> createState() => _ScenarioDecisionWidgetState();
}

class _ScenarioDecisionWidgetState extends State<ScenarioDecisionWidget> {
  int? selectedOptionIndex;
  bool showFeedback = false;
  bool isCorrect = false;
  String feedback = '';
  
  late String scenario;
  late List<Map<String, dynamic>> options;

  @override
  void initState() {
    super.initState();
    _initializeScenario();
  }

  void _initializeScenario() {
    // Parse scenario data
    final questionData = widget.questionData;
    
    // Get scenario text from title or description
    scenario = questionData['title'] ?? questionData['scenario'] ?? 'Make your decision...';
    
    // Parse options
    if (questionData['options'] != null) {
      if (questionData['options'] is String) {
        final parsed = jsonDecode(questionData['options']);
        options = List<Map<String, dynamic>>.from(parsed);
      } else if (questionData['options'] is List) {
        options = List<Map<String, dynamic>>.from(questionData['options']);
      } else {
        options = [];
      }
    } else if (questionData['options_data'] != null) {
      options = List<Map<String, dynamic>>.from(questionData['options_data']);
    } else {
      options = [];
    }
  }

  void _selectOption(int index) {
    if (showFeedback) return; // Already selected
    
    setState(() {
      selectedOptionIndex = index;
      showFeedback = true;
      
      final option = options[index];
      isCorrect = option['is_correct'] == true;
      feedback = option['feedback'] ?? (isCorrect 
          ? '✅ Great decision! This is the right approach.' 
          : '❌ Not quite. Consider the implications of this choice.');
    });

    // Calculate score
    final score = isCorrect ? 100 : 0;
    
    // Auto-submit after showing feedback
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onAnswerSubmitted(score, isCorrect);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scenario Card
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF4EF8B).withOpacity(0.1),
                  const Color(0xFFE8D96F).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF4EF8B).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D96F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Scenario',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE8D96F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    scenario,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: Color(0xFF1A2F4B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.questionData['description'] != null && 
                      widget.questionData['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.questionData['description'],
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: const Color(0xFF1A2F4B).withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Decision Prompt
        const Text(
          'What would you do?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2F4B),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        // Options
        Expanded(
          flex: 3,
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final option = options[index];
              final optionText = option['text'] ?? option['option_text'] ?? 'Option ${index + 1}';
              final isSelected = selectedOptionIndex == index;
              final isOptionCorrect = option['is_correct'] == true;
              
              // Determine color based on state
              Color borderColor;
              Color backgroundColor;
              Color textColor = const Color(0xFF1A2F4B);
              
              if (showFeedback) {
                if (isSelected) {
                  if (isCorrect) {
                    borderColor = Colors.green;
                    backgroundColor = Colors.green.withOpacity(0.1);
                  } else {
                    borderColor = Colors.red;
                    backgroundColor = Colors.red.withOpacity(0.1);
                  }
                } else if (isOptionCorrect) {
                  // Show correct answer
                  borderColor = Colors.green.withOpacity(0.5);
                  backgroundColor = Colors.green.withOpacity(0.05);
                } else {
                  borderColor = Colors.grey.withOpacity(0.3);
                  backgroundColor = Colors.grey.withOpacity(0.05);
                }
              } else {
                borderColor = const Color(0xFFF4EF8B).withOpacity(0.3);
                backgroundColor = Colors.white;
              }
              
              return InkWell(
                onTap: showFeedback ? null : () => _selectOption(index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected && !showFeedback
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF4EF8B).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      // Option Letter
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: showFeedback && isSelected
                              ? (isCorrect ? Colors.green : Colors.red)
                              : const Color(0xFFE8D96F),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: showFeedback && isSelected
                              ? Icon(
                                  isCorrect ? Icons.check : Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Option Text
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      
                      // Correct indicator
                      if (showFeedback && isOptionCorrect)
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
          ),
        ),
        
        // Feedback Section
        if (showFeedback) ...[
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.lightbulb : Icons.info_outline,
                  color: isCorrect ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feedback,
                    style: TextStyle(
                      fontSize: 15,
                      color: isCorrect ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
