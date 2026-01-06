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
  bool _isLoading = true;
  bool _selectionMode = false;
  Set<String> _selectedQuestions = {};
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadDepartments();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('questions')
          .select('*, quest_types(type)')
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(response);
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
    
    // Handle tags - could be List or String
    String tagsText = '';
    if (question['tags'] is List) {
      tagsText = (question['tags'] as List).join(', ');
    } else if (question['tags'] != null) {
      tagsText = question['tags'].toString();
    }
    final tagsController = TextEditingController(text: tagsText);
    
    String selectedDifficulty = question['difficulty'] ?? 'easy';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., sales, customer-service',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client
                      .from('questions')
                      .update({
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'difficulty': selectedDifficulty,
                        'points': int.tryParse(pointsController.text) ?? 10,
                        'tags': tagsController.text,
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
              ),
              child: const Text('Save'),
            ),
          ],
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
                const SizedBox(height: 12),
                if (_selectionMode)
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _toggleSelectionMode,
                        icon: const Icon(Icons.close),
                        label: Text('Cancel (${_selectedQuestions.length} selected)'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _toggleSelectionMode,
                        icon: const Icon(Icons.checklist),
                        label: const Text('Select Questions'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
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
                                          Expanded(
                                            child: Text(
                                              question['title'] ?? 'No title',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
