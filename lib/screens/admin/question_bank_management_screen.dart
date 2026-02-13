import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_question_screen.dart';

class QuestionBankManagementScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const QuestionBankManagementScreen({super.key, this.onBack});

  @override
  State<QuestionBankManagementScreen> createState() => _QuestionBankManagementScreenState();
}

class _QuestionBankManagementScreenState extends State<QuestionBankManagementScreen> {
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _allQuestions = []; // Store all questions
  bool _isLoading = true;
  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentFilter; // Filter by department
  int? _selectedLevelFilter; // Filter by level
  final Set<int> _collapsedLevels = {};
  final Set<String> _collapsedDepts = {}; // key: 'level_dept'
  bool _deptDefaultsInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadDepartments();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      // Load departments first to create a lookup map
      final deptResponse = await Supabase.instance.client
          .from('departments')
          .select('id, title, category');
      
      final deptMap = <String, String>{};
      for (var dept in deptResponse) {
        final title = dept['title'] ?? 'Unknown';
        final category = dept['category'];
        // For General departments, show "General - Category"
        if (title == 'General' && category != null) {
          deptMap[dept['id']] = 'General - $category';
        } else {
          deptMap[dept['id']] = title;
        }
      }
      
      // Load questions ordered by level then department for grouped display
      final response = await Supabase.instance.client
          .from('questions')
          .select('*, quest_types(type)')
          .order('level', ascending: true)
          .order('dept_id', ascending: true)
          .order('created_at', ascending: false);
      
      // Add department title to each question
      for (var question in response) {
        final deptId = question['dept_id'];
        if (deptId != null && deptMap.containsKey(deptId)) {
          question['department_title'] = deptMap[deptId];
        } else {
          question['department_title'] = 'No Dept';
        }
      }
      
      if (mounted) {
        setState(() {
          _allQuestions = List<Map<String, dynamic>>.from(response);
          _questions = _allQuestions; // Initially show all
          _isLoading = false;
        });
        _filterQuestions();
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select('id, title, category')
          .order('title');
      
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error loading departments: $e');
    }
  }

  void _filterQuestions() {
    setState(() {
      _questions = _allQuestions.where((q) {
        bool matchesDept = true;
        bool matchesLevel = true;

        if (_selectedDepartmentFilter != null && _selectedDepartmentFilter!.isNotEmpty) {
          matchesDept = q['dept_id'] == _selectedDepartmentFilter;
        }

        if (_selectedLevelFilter != null) {
          matchesLevel = (q['level'] ?? 1) == _selectedLevelFilter;
        }

        return matchesDept && matchesLevel;
      }).toList();
    });
  }



  Future<void> _showQuestionDetails(Map<String, dynamic> question) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(question['title'] ?? 'Question Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (question['description'] != null) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(question['description']),
                const SizedBox(height: 16),
              ],
              const Text(
                'Level:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Level ${question['level'] ?? 1}'),
              const SizedBox(height: 16),
              const Text(
                'Points:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(question['points']?.toString() ?? '0'),
              const SizedBox(height: 16),
              const Text(
                'Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                question['tags'] is List 
                    ? (question['tags'] as List).join(', ')
                    : (question['tags']?.toString() ?? 'None')
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(question);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> question) async {
    final titleController = TextEditingController(text: question['title']);
    final descriptionController = TextEditingController(text: question['description']);
    final pointsController = TextEditingController(text: question['points']?.toString() ?? '10');
    
    int selectedLevel = question['level'] ?? 1;
    
    // Get question type
    String questionType = 'mcq'; // default
    if (question['quest_types'] != null && question['quest_types'] is Map) {
      questionType = question['quest_types']['type'] ?? 'mcq';
    }
    
    // Parse existing options (only for MCQ/Scenario questions)
    List<Map<String, dynamic>> options = [];
    bool isCardMatch = questionType == 'card_match';
    
    if (!isCardMatch && question['options'] != null) {
      try {
        final optionsList = question['options'] as List;
        for (var opt in optionsList) {
          if (opt is Map) {
            options.add({
              'text': opt['text']?.toString() ?? '',
              'is_correct': opt['is_correct'] == true,
            });
          } else {
            // Handle old format (plain strings)
            options.add({
              'text': opt.toString(),
              'is_correct': false,
            });
          }
        }
      } catch (e) {
        debugPrint('Error parsing options: $e');
      }
    }
    
    // If no options and not card match, add 4 empty ones for MCQ
    if (options.isEmpty && !isCardMatch) {
      options = List.generate(4, (index) => {'text': '', 'is_correct': false});
    }

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), // Darker overlay for more contrast
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                      offset: const Offset(0, 15),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF6BCB9F),
                    width: 4,
                  ),
                ),
                child: SizedBox(
                  width: constraints.maxWidth - 48,
                  height: constraints.maxHeight - 48,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Question',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2F4B),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 24),
                              onPressed: () => Navigator.pop(context),
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                        const Divider(thickness: 2),
                        const SizedBox(height: 12),
                        // Scrollable content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Level 1 (Easy)')),
                      DropdownMenuItem(value: 2, child: Text('Level 2 (Medium)')),
                      DropdownMenuItem(value: 3, child: Text('Level 3 (Hard)')),
                      DropdownMenuItem(value: 4, child: Text('Level 4 (Expert)')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLevel = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pointsController,
                    decoration: const InputDecoration(
                      labelText: 'Points',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // Options section (only for MCQ/Scenario questions)
                  if (!isCardMatch) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Options (Multiple Choice)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF6BCB9F), size: 20),
                          onPressed: () {
                            setDialogState(() {
                              options.add({'text': '', 'is_correct': false});
                            });
                          },
                          tooltip: 'Add Option',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...List.generate(options.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              child: Checkbox(
                                value: options[index]['is_correct'],
                                onChanged: (value) {
                                  setDialogState(() {
                                    options[index]['is_correct'] = value ?? false;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Option ${index + 1}',
                                  border: const OutlineInputBorder(),
                                  hintText: 'Enter option text',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  isDense: true,
                                ),
                                controller: TextEditingController(text: options[index]['text'])
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(offset: options[index]['text'].length),
                                  ),
                                onChanged: (value) {
                                  options[index]['text'] = value;
                                },
                              ),
                            ),
                            if (options.length > 2)
                              SizedBox(
                                width: 40,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      options.removeAt(index);
                                    });
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    // Show message for Card Match questions
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF3B82F6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Card Match questions cannot be edited here. Please create a new question to modify the card configuration.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(thickness: 1),
                const SizedBox(height: 12),
                // Footer buttons
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // Prepare options data
                            final optionsData = options
                                .where((opt) => opt['text'].toString().trim().isNotEmpty)
                                .map((opt) => {
                                      'text': opt['text'],
                                      'is_correct': opt['is_correct'],
                                    })
                                .toList();

                            await Supabase.instance.client
                                .from('questions')
                                .update({
                                  'title': titleController.text,
                                  'description': descriptionController.text,
                                  'level': selectedLevel,
                                  'points': int.tryParse(pointsController.text) ?? 10,
                                  'options': optionsData,
                                })
                                .eq('id', question['id']);

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Question updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadQuestions();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _deleteQuestion(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('questions')
            .delete()
            .eq('id', questionId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadQuestions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting question: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Get question type display info
  ({String name, Color color, Color bg}) _getQuestionTypeInfo(Map<String, dynamic> question) {
    String questionType = 'match';
    if (question['quest_types'] != null && question['quest_types'] is Map) {
      questionType = question['quest_types']['type'] ?? 'match';
    }
    switch (questionType) {
      case 'mcq':
        return (name: 'MCQ', color: const Color(0xFF10B981), bg: const Color(0xFF10B981).withOpacity(0.1));
      case 'match':
        return (name: 'Match', color: const Color(0xFFEC4899), bg: const Color(0xFFEC4899).withOpacity(0.1));
      case 'card_match':
        return (name: 'Card Match', color: const Color(0xFF3B82F6), bg: const Color(0xFF3B82F6).withOpacity(0.1));
      case 'scenario_decision':
        return (name: 'Scenario', color: const Color(0xFF9B59B6), bg: const Color(0xFF9B59B6).withOpacity(0.1));
      case 'sequence_builder':
        return (name: 'Sequence', color: const Color(0xFF00BCD4), bg: const Color(0xFF00BCD4).withOpacity(0.1));
      case 'simulation':
        return (name: 'Simulation', color: const Color(0xFF6BCB9F), bg: const Color(0xFF6BCB9F).withOpacity(0.1));
      default:
        return (name: 'Unknown', color: Colors.grey, bg: Colors.grey.withOpacity(0.1));
    }
  }

  /// Build grouped question list: Level → Department → Questions
  Widget _buildGroupedQuestionList() {
    // Group questions by level, then by department
    final Map<int, Map<String, List<Map<String, dynamic>>>> grouped = {};

    for (final q in _questions) {
      final level = (q['level'] as int?) ?? 1;
      final dept = (q['department_title'] as String?) ?? 'No Dept';
      grouped.putIfAbsent(level, () => {});
      grouped[level]!.putIfAbsent(dept, () => []);
      grouped[level]![dept]!.add(q);
    }

    // Sort levels
    final sortedLevels = grouped.keys.toList()..sort();

    // Collapse all departments by default on first load
    if (!_deptDefaultsInitialized) {
      _deptDefaultsInitialized = true;
      for (final level in sortedLevels) {
        for (final dept in grouped[level]!.keys) {
          _collapsedDepts.add('${level}_$dept');
        }
      }
    }

    final List<Widget> items = [];

    for (final level in sortedLevels) {
      final deptMap = grouped[level]!;
      final sortedDepts = deptMap.keys.toList()..sort();

      // Count total questions at this level
      int levelTotal = 0;
      for (final d in sortedDepts) {
        levelTotal += deptMap[d]!.length;
      }

      final isLevelCollapsed = _collapsedLevels.contains(level);

      // Level header (tappable to collapse/expand)
      items.add(
        GestureDetector(
          onTap: () {
            setState(() {
              if (isLevelCollapsed) {
                _collapsedLevels.remove(level);
              } else {
                _collapsedLevels.add(level);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F4B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isLevelCollapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
                  size: 20, color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Level $level',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$levelTotal Qs',
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (isLevelCollapsed) continue;

      for (final dept in sortedDepts) {
        final questions = deptMap[dept]!;

        final deptKey = '${level}_$dept';
        final isDeptCollapsed = _collapsedDepts.contains(deptKey);

        // Department sub-header (tappable to collapse/expand)
        items.add(
          GestureDetector(
            onTap: () {
              setState(() {
                if (isDeptCollapsed) {
                  _collapsedDepts.remove(deptKey);
                } else {
                  _collapsedDepts.add(deptKey);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 4, bottom: 2, left: 24, right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    isDeptCollapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
                    size: 16, color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dept,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  Text(
                    '${questions.length}',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );

        if (isDeptCollapsed) continue;

        // Question cards under this department
        for (final question in questions) {
          final typeInfo = _getQuestionTypeInfo(question);

          items.add(
            Card(
              margin: const EdgeInsets.only(bottom: 4, left: 32, right: 16, top: 2),
              elevation: 0.5,
              child: InkWell(
                onTap: () => _showQuestionDetails(question),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (question['description'] != null && question['description'].toString().isNotEmpty)
                                  ? question['description']
                                  : question['title'] ?? 'No title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A2F4B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Type badge + points
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: typeInfo.bg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    typeInfo.name,
                                    style: TextStyle(fontSize: 10, color: typeInfo.color, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${question['points'] ?? 10} pts',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            color: Colors.blue,
                            onPressed: () => _showEditDialog(question),
                            tooltip: 'Edit',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16),
                            color: Colors.red,
                            onPressed: () => _deleteQuestion(question['id']),
                            tooltip: 'Delete',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9E6), // Very light yellow
              Color(0xFFF4EF8B), // Main yellow #f4ef8b
              Color(0xFFE8D96F), // Darker yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: widget.onBack,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF1A2F4B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Question Bank',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2F4B),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      width: 32,
                      child: FloatingActionButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddQuestionScreen(),
                            ),
                          );
                          _loadQuestions();
                        },
                        backgroundColor: const Color(0xFF3B82F6),
                        elevation: 2,
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Department Filter and Select Questions in one row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedDepartmentFilter,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                          prefixIcon: Icon(Icons.filter_list, size: 18),
                        ),
                        isExpanded: true,
                        hint: const Text('All Departments'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Departments'),
                          ),
                          ..._departments.map((dept) {
                            final title = dept['title'] ?? 'Unknown';
                            final category = dept['category'];
                            // For General departments, show "General - Category"
                            final displayName = (title == 'General' && category != null)
                                ? 'General - $category'
                                : title;
                            
                            return DropdownMenuItem<String>(
                              value: dept['id'],
                              child: Text(
                                displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentFilter = value;
                          });
                          _filterQuestions();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),


                    // Level Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _selectedLevelFilter,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        isExpanded: true,
                        hint: const Text('All Levels'),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('All Levels'),
                          ),
                          ...[1, 2, 3, 4].map((level) {
                            return DropdownMenuItem<int>(
                              value: level,
                              child: Text('Level $level'),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedLevelFilter = value;
                          });
                          _filterQuestions();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
              ],
            ),
          ),
          // Questions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No questions found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddQuestionScreen(),
                                  ),
                                );
                                _loadQuestions();
                              },
                              child: const Text('Add your first question'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadQuestions,
                        child: _buildGroupedQuestionList(),
                      ),
            ),
          ],
        ),
        ),
      ),

    );
  }
}
