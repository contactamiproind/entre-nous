import 'package:flutter/material.dart';

class BudgetAllocationWidget extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final Function(int score, bool isCorrect) onAnswerSubmitted;

  const BudgetAllocationWidget({
    super.key,
    required this.questionData,
    required this.onAnswerSubmitted,
  });

  @override
  State<BudgetAllocationWidget> createState() => _BudgetAllocationWidgetState();
}

class _BudgetAllocationWidgetState extends State<BudgetAllocationWidget> {
  late int totalBudget;
  late List<Map<String, dynamic>> departments;
  Map<int, int?> departmentAllocations = {}; // dept_id -> amount
  List<int> availableAmounts = [];
  bool isSubmitted = false;
  Map<int, bool> departmentResults = {};
  int finalScore = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    debugPrint('🎮 BudgetAllocationWidget._initializeGame()');
    
    final options = widget.questionData['options'];
    debugPrint('   Options type: ${options.runtimeType}');
    debugPrint('   Options value: $options');

    if (options == null) {
      debugPrint('   ERROR: Budget simulation has null options');
      return;
    }

    // Parse options
    if (options is Map) {
      totalBudget = options['total_budget'] ?? 10000;
      
      final deptList = options['departments'];
      if (deptList is List) {
        departments = List<Map<String, dynamic>>.from(
          deptList.map((dept) => Map<String, dynamic>.from(dept))
        );
      } else {
        departments = [];
      }
    } else {
      totalBudget = 10000;
      departments = [];
    }

    // Initialize allocations
    for (var dept in departments) {
      departmentAllocations[dept['id']] = null;
    }

    // Create list of available amounts (shuffled)
    availableAmounts = departments.map<int>((dept) => dept['correct_amount'] as int).toList();
    availableAmounts.shuffle();

    debugPrint('Budget simulation initialized: $totalBudget budget, ${departments.length} departments');
    debugPrint('Available amounts: $availableAmounts');
  }

  void _onAmountDropped(int deptId, int amount) {
    setState(() {
      // Remove amount from any previous department
      departmentAllocations.forEach((key, value) {
        if (value == amount) {
          departmentAllocations[key] = null;
        }
      });
      
      // Assign to new department
      departmentAllocations[deptId] = amount;
    });
  }

  bool get canSubmit {
    return departmentAllocations.values.every((amount) => amount != null);
  }

  void _submitBudget() {
    if (!canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Please assign amounts to all departments!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF08A7E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Calculate score
    int correctMatches = 0;

    for (var dept in departments) {
      final deptId = dept['id'];
      final correctAmount = dept['correct_amount'];
      final allocatedAmount = departmentAllocations[deptId];

      bool isCorrect = allocatedAmount == correctAmount;
      departmentResults[deptId] = isCorrect;
      
      if (isCorrect) {
        correctMatches++;
      }
    }

    // Calculate final score (0-100)
    finalScore = ((correctMatches / departments.length) * 100).round();

    setState(() {
      isSubmitted = true;
    });

    // Notify parent
    widget.onAnswerSubmitted(finalScore, finalScore >= 70);
  }

  @override
  Widget build(BuildContext context) {
    if (departments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading budget simulation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        // Question Title
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.questionData['title'] ?? 'Match budget amounts to departments',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        // Description
        if (widget.questionData['description'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.questionData['description'],
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 16),

        // Total Budget Display
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6BCB9F), Color(0xFF4CAF90)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6BCB9F).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'TOTAL BUDGET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${totalBudget.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Department Drop Zones
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final dept = departments[index];
              final deptId = dept['id'];
              final deptName = dept['name'];
              final allocatedAmount = departmentAllocations[deptId];

              Color cardColor = Colors.white;
              IconData? resultIcon;
              Color? resultColor;

              if (isSubmitted) {
                final isCorrect = departmentResults[deptId] ?? false;
                if (isCorrect) {
                  cardColor = const Color(0xFF6BCB9F).withOpacity(0.1);
                  resultIcon = Icons.check_circle;
                  resultColor = const Color(0xFF6BCB9F);
                } else {
                  cardColor = const Color(0xFFF08A7E).withOpacity(0.1);
                  resultIcon = Icons.cancel;
                  resultColor = const Color(0xFFF08A7E);
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: DragTarget<int>(
                  onAccept: isSubmitted ? null : (amount) => _onAmountDropped(deptId, amount),
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isHovering ? const Color(0xFF6BCB9F).withOpacity(0.1) : cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isHovering 
                              ? const Color(0xFF6BCB9F)
                              : isSubmitted
                                  ? (resultColor ?? Colors.grey.shade300)
                                  : Colors.grey.shade300,
                          width: isHovering ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Department Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6BCB9F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Color(0xFF6BCB9F),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Department Name
                          Expanded(
                            child: Text(
                              deptName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2F4B),
                              ),
                            ),
                          ),
                          
                          // Allocated Amount or Drop Zone
                          if (allocatedAmount != null)
                            Draggable<int>(
                              data: allocatedAmount,
                              feedback: Material(
                                color: Colors.transparent,
                                child: _buildAmountChip(allocatedAmount, isDragging: true),
                              ),
                              childWhenDragging: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.solid),
                                ),
                                child: const Text(
                                  'Dragging...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              child: _buildAmountChip(allocatedAmount),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isHovering ? const Color(0xFF6BCB9F).withOpacity(0.2) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isHovering ? const Color(0xFF6BCB9F) : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Drop Here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isHovering ? const Color(0xFF6BCB9F) : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          
                          // Result Icon
                          if (isSubmitted && resultIcon != null) ...[
                            const SizedBox(width: 12),
                            Icon(resultIcon, color: resultColor, size: 28),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Available Amounts (if not submitted)
        if (!isSubmitted) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Available Amounts (Drag to Departments)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2F4B),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: availableAmounts.where((amount) {
                // Only show amounts that haven't been assigned
                return !departmentAllocations.values.contains(amount);
              }).map((amount) {
                return Draggable<int>(
                  data: amount,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _buildAmountChip(amount, isDragging: true),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildAmountChip(amount),
                  ),
                  child: _buildAmountChip(amount),
                );
              }).toList(),
            ),
          ),
        ],

        // Submit Button or Score Display
        Padding(
          padding: const EdgeInsets.all(16),
          child: isSubmitted
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: finalScore >= 70
                        ? const Color(0xFF6BCB9F).withOpacity(0.1)
                        : const Color(0xFFF08A7E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: finalScore >= 70
                          ? const Color(0xFF6BCB9F)
                          : const Color(0xFFF08A7E),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        finalScore >= 70 ? Icons.celebration : Icons.info_outline,
                        size: 48,
                        color: finalScore >= 70
                            ? const Color(0xFF6BCB9F)
                            : const Color(0xFFF08A7E),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Score: $finalScore/100',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: finalScore >= 70
                              ? const Color(0xFF6BCB9F)
                              : const Color(0xFFF08A7E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        finalScore >= 70
                            ? 'Great job! You matched the budgets correctly!'
                            : 'Try to match the correct amounts to each department.',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _submitBudget : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6BCB9F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      'SUBMIT BUDGET',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAmountChip(int amount, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDragging
              ? [const Color(0xFF6BCB9F), const Color(0xFF4CAF90)]
              : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDragging ? const Color(0xFF6BCB9F) : const Color(0xFF3B82F6)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '\$${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
