import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_question_screen.dart';

class DepartmentQuestionsScreen extends StatefulWidget {
  final String departmentId;
  final String departmentName;

  const DepartmentQuestionsScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  State<DepartmentQuestionsScreen> createState() => _DepartmentQuestionsScreenState();
}

class _DepartmentQuestionsScreenState extends State<DepartmentQuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('questions')
          .select()
          .eq('dept_id', widget.departmentId)
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

  Future<void> _showEditDialog(Map<String, dynamic> question) async {
    final titleController = TextEditingController(text: question['title']);
    final descriptionController = TextEditingController(text: question['description']);
    final pointsController = TextEditingController(text: question['points']?.toString() ?? '10');
    
    String tagsText = '';
    if (question['tags'] is List) {
      tagsText = (question['tags'] as List).join(', ');
    } else if (question['tags'] != null) {
      tagsText = question['tags'].toString();
    }
    final tagsController = TextEditingController(text: tagsText);
    
    // Get level as integer
    int selectedLevel = question['level'] ?? 1;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Question'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
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
                  DropdownButtonFormField<int>(
                    value: selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Convert tags string to array
                  List<String> tagsArray = [];
                  if (tagsController.text.trim().isNotEmpty) {
                    tagsArray = tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();
                  }
                  
                  await Supabase.instance.client
                      .from('questions')
                      .update({
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'level': selectedLevel,
                        'points': int.tryParse(pointsController.text) ?? 10,
                        'tags': tagsArray,
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

  /// Get question type info for badge display
  Map<String, dynamic> _getQuestionTypeInfo(Map<String, dynamic> question) {
    final typeId = question['type_id']?.toString() ?? '';
    if (typeId == '90a72b93-ce01-44d9-8a93-c4ec2edd25a1') {
      return {'label': 'MCQ', 'color': const Color(0xFF10B981)};
    } else {
      return {'label': 'Match', 'color': const Color(0xFFEC4899)};
    }
  }

  /// Get level color
  Color _getLevelColor(int level) {
    switch (level) {
      case 1: return const Color(0xFF10B981);
      case 2: return const Color(0xFF3B82F6);
      case 3: return const Color(0xFFF59E0B);
      case 4: return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF9E6),
            Color(0xFFF4EF8B),
            Color(0xFFE8D96F),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Compact header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF1A2F4B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.departmentName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A2F4B)),
                        overflow: TextOverflow.ellipsis,
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
                              builder: (context) => AddQuestionScreen(
                                departmentId: widget.departmentId,
                              ),
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
              ),
              // Questions list grouped by level
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _questions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.quiz_outlined, size: 40, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('No questions found', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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

  Widget _buildGroupedQuestionList() {
    // Group questions by level
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    for (final q in _questions) {
      final level = q['level'] is int ? q['level'] as int : 1;
      grouped.putIfAbsent(level, () => []);
      grouped[level]!.add(q);
    }
    final sortedLevels = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        for (final level in sortedLevels) ...[
          // Level header
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6, left: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getLevelColor(level).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Level $level',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _getLevelColor(level)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${grouped[level]!.length} questions',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          // Questions in this level
          for (final question in grouped[level]!) ...[
            _buildQuestionCard(question, level),
            const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int level) {
    final typeInfo = _getQuestionTypeInfo(question);
    final description = question['description']?.toString() ?? '';
    final title = question['title']?.toString() ?? 'No title';
    final primaryText = description.isNotEmpty ? description : title;
    final points = question['points'] ?? 10;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level dot
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: _getLevelColor(level),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A2F4B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (typeInfo['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          typeInfo['label'] as String,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: typeInfo['color'] as Color),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Points badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2F4B).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '$points pts',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF1A2F4B)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            InkWell(
              onTap: () => _showEditDialog(question),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined, size: 14, color: Colors.blue),
              ),
            ),
            const SizedBox(width: 2),
            InkWell(
              onTap: () => _deleteQuestion(question['id']),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, size: 14, color: Colors.red.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
