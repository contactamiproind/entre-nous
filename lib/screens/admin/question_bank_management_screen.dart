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
  bool _selectionMode = false;
  Set<String> _selectedQuestions = {};
  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentFilter; // Filter by department

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
          .select('id, title');
      
      final deptMap = <String, String>{};
      for (var dept in deptResponse) {
        deptMap[dept['id']] = dept['title'];
      }
      
      // Load questions
      final response = await Supabase.instance.client
          .from('questions')
          .select('*, quest_types(type)')
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
          .select('id, title')
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
      if (_selectedDepartmentFilter == null || _selectedDepartmentFilter!.isEmpty) {
        _questions = _allQuestions;
      } else {
        _questions = _allQuestions.where((q) => q['dept_id'] == _selectedDepartmentFilter).toList();
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedQuestions.clear();
      }
    });
  }

  void _toggleQuestionSelection(String questionId) {
    setState(() {
      if (_selectedQuestions.contains(questionId)) {
        _selectedQuestions.remove(questionId);
      } else {
        _selectedQuestions.add(questionId);
      }
    });
  }

  Future<void> _showBulkAssignDialog() async {
    String? selectedDeptId;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign ${_selectedQuestions.length} Questions'),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select department to assign these questions to:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDeptId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                    items: _departments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept['id'],
                        child: Text(
                          dept['title'] ?? 'Unknown',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDeptId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDeptId == null
                  ? null
                  : () async {
                      await _bulkAssignQuestions(selectedDeptId!);
                      if (mounted) Navigator.pop(context);
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkAssignQuestions(String deptId) async {
    try {
      for (String questionId in _selectedQuestions) {
        await Supabase.instance.client
            .from('questions')
            .update({'dept_id': deptId})
            .eq('id', questionId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedQuestions.length} questions assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectionMode = false;
          _selectedQuestions.clear();
        });
        _loadQuestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning questions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                'Difficulty:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(question['difficulty'] ?? 'Not set'),
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
    
    String selectedDifficulty = question['difficulty'] ?? 'easy';
    
    // Parse existing options
    List<Map<String, dynamic>> options = [];
    if (question['options'] != null) {
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
    
    // If no options, add 4 empty ones for MCQ
    if (options.isEmpty) {
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
                  DropdownButtonFormField<String>(
                    value: selectedDifficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDifficulty = value!;
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
                  // Options section
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
                                  'difficulty': selectedDifficulty,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: widget.onBack,
                        ),
                        const Text(
                          'Question Bank',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2F4B),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddQuestionScreen(),
                          ),
                        );
                        _loadQuestions();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Department Filter and Select Questions in one row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
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
                            return DropdownMenuItem<String>(
                              value: dept['id'],
                              child: Text(
                                dept['title'] ?? 'Unknown',
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
                    if (_selectionMode)
                      Flexible(
                        flex: 1,
                        child: TextButton.icon(
                          onPressed: _toggleSelectionMode,
                          icon: const Icon(Icons.close, size: 18),
                          label: Text('Cancel (${_selectedQuestions.length})'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        flex: 1,
                        child: TextButton.icon(
                          onPressed: _toggleSelectionMode,
                          icon: const Icon(Icons.checklist, size: 18),
                          label: const Text('Select'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
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
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            
                            // Get the question type from the joined quest_types table
                            String questionType = 'match'; // default
                            if (question['quest_types'] != null && question['quest_types'] is Map) {
                              questionType = question['quest_types']['type'] ?? 'match';
                            }
                            
                            // Determine display name and color
                            String typeName;
                            Color typeColor;
                            Color bgColor;
                            
                            switch (questionType) {
                              case 'mcq':
                                typeName = 'Multiple Choice';
                                typeColor = const Color(0xFF10B981);
                                bgColor = const Color(0xFF10B981).withOpacity(0.1);
                                break;
                              case 'match':
                                typeName = 'Match Following';
                                typeColor = const Color(0xFFEC4899);
                                bgColor = const Color(0xFFEC4899).withOpacity(0.1);
                                break;
                              case 'card_match':
                                typeName = 'Card Match';
                                typeColor = const Color(0xFF3B82F6);
                                bgColor = const Color(0xFF3B82F6).withOpacity(0.1);
                                break;
                              case 'scenario_decision':
                                typeName = 'Scenario Decision';
                                typeColor = const Color(0xFF9B59B6);
                                bgColor = const Color(0xFF9B59B6).withOpacity(0.1);
                                break;
                              default:
                                typeName = 'Unknown';
                                typeColor = Colors.grey;
                                bgColor = Colors.grey.withOpacity(0.1);
                            }
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => _showQuestionDetails(question),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                      // Title and action buttons row
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                          if (_selectionMode)
                                            Checkbox(
                                              value: _selectedQuestions.contains(question['id']),
                                              onChanged: (value) {
                                                _toggleQuestionSelection(question['id']);
                                              },
                                             ),
                                          // Department badge removed - using filter instead
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  question['title'] ?? 'No title',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF1A2F4B),
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (question['description'] != null && 
                                                    question['description'].toString().isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    question['description'],
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18),
                                                color: Colors.blue,
                                                onPressed: () => _showEditDialog(question),
                                                tooltip: 'Edit',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18),
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
                                      const SizedBox(height: 8),
                                      // Type badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          typeName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: typeColor,
                                            fontWeight: FontWeight.w600,
                                          ),
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
        ],
      ),
      floatingActionButton: _selectionMode && _selectedQuestions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkAssignDialog,
              icon: const Icon(Icons.assignment),
              label: Text('Assign ${_selectedQuestions.length}'),
              backgroundColor: const Color(0xFF3B82F6),
            )
          : null,
    );
  }
}
