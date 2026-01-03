import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pathway.dart';
import '../services/pathway_service.dart';

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final PathwayService _pathwayService = PathwayService();
  
  // State
  List<Pathway> _pathways = [];
  List<PathwayLevel> _levels = [];
  Pathway? _selectedPathway;
  PathwayLevel? _selectedLevel;
  bool _isLoadingPathways = true;
  bool _isLoadingLevels = false;
  bool _isSaving = false;

  // Question Type
  String _questionType = 'multiple_choice'; // 'multiple_choice' or 'match_following'
  
  // Subcategory
  String? _selectedSubcategory;

  // Title and Description
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Multiple Choice Form Data
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4, 
    (index) => TextEditingController(),
  );
  int _correctDisplayIndex = 0; // 0-3

  // Match the Following Form Data
  final List<Map<String, TextEditingController>> _matchPairs = [];

  void _addMatchPair() {
    if (_matchPairs.length < 6) {
      setState(() {
        _matchPairs.add({
          'left': TextEditingController(),
          'right': TextEditingController(),
        });
      });
    }
  }

  void _removeMatchPair(int index) {
    if (_matchPairs.length > 3) {
      setState(() {
        _matchPairs[index]['left']!.dispose();
        _matchPairs[index]['right']!.dispose();
        _matchPairs.removeAt(index);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    // Initialize with 3 match pairs
    for (int i = 0; i < 3; i++) {
      _addMatchPair();
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final pathways = await _pathwayService.getAllPathways();
      setState(() {
        _pathways = pathways;
        _isLoadingPathways = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pathways: $e')),
        );
        setState(() => _isLoadingPathways = false);
      }
    }
  }

  Future<void> _loadLevels(Pathway pathway) async {
    setState(() {
      _selectedPathway = pathway;
      _selectedLevel = null;
      _isLoadingLevels = true;
    });

    try {
      final levels = await _pathwayService.getPathwayLevels(pathway.id);
      setState(() {
        _levels = levels;
        _isLoadingLevels = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading levels: $e')),
        );
        setState(() => _isLoadingLevels = false);
      }
    }
  }

  Future<void> _generateDefaultLevels() async {
    if (_selectedPathway == null) return;
    
    setState(() => _isLoadingLevels = true);
    
    try {
      // Default levels
      final defaults = [
        {'number': 1, 'name': 'Beginner', 'score': 0},
        {'number': 2, 'name': 'Intermediate', 'score': 500},
        {'number': 3, 'name': 'Advanced', 'score': 1500},
      ];
      
      for (var lvl in defaults) {
        await _pathwayService.createPathwayLevel(
          pathwayId: _selectedPathway!.id,
          levelNumber: lvl['number'] as int,
          levelName: lvl['name'] as String,
          requiredScore: lvl['score'] as int,
          description: '${lvl['name']} level for ${_selectedPathway!.title}',
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default levels generated successfully!')),
        );
      }
      
      // Reload list
      await _loadLevels(_selectedPathway!);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating levels: $e')),
        );
        setState(() => _isLoadingLevels = false);
      }
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a level')),
      );
      return;
    }

    // Validate based on question type
    if (_questionType == 'match_following') {
      if (_matchPairs.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least 3 match pairs')),
        );
        return;
      }
      // Check if all pairs are filled
      for (var pair in _matchPairs) {
        if (pair['left']!.text.trim().isEmpty || pair['right']!.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all match pairs')),
          );
          return;
        }
      }
    }


    setState(() => _isSaving = true);

    try {
      // Map level name to difficulty for backward compatibility
    String difficulty = 'easy'; // default
    final levelName = _selectedLevel?.levelName?.toLowerCase() ?? 'easy';
    if (levelName.contains('mid') || levelName.contains('medium')) {
      difficulty = 'medium';
    } else if (levelName.contains('hard')) {
      difficulty = 'hard';
    } else if (levelName.contains('extreme')) {
      difficulty = 'hard';
    } else if (levelName.contains('easy')) {
      difficulty = 'easy';
    }

    // Map UI types to DB types
    String dbType = _questionType;
    if (_questionType == 'multiple_choice') dbType = 'mcq';
    if (_questionType == 'match_following') dbType = 'match';
    
    // Get type_id from quest_types table
    final typeRes = await Supabase.instance.client
        .from('quest_types')
        .select('id')
        .eq('type', dbType)
        .maybeSingle();

    if (typeRes == null) {
      throw 'Question type "$dbType" not found in database';
    }

    Map<String, dynamic> questionData = {
      'dept_id': _selectedPathway!.id,
      'level_id': _selectedLevel!.id, // SAVE LEVEL ID
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type_id': typeRes['id'], // Use type_id instead of question_type
      'difficulty': difficulty,
      'points': 10,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (_questionType == 'multiple_choice') {
      // Prepare options array
      final options = _optionControllers.map((controller) => controller.text.trim()).toList();
      // Use the Option text itself as the correct answer for better matching
      final correctAnswerText = options[_correctDisplayIndex];
      
      questionData['options'] = options;
      questionData['correct_answer'] = correctAnswerText;
    } else if (_questionType == 'match_following') {
      // Prepare match pairs
      final matchPairs = _matchPairs.map((pair) => {
        'left': pair['left']!.text.trim(),
        'right': pair['right']!.text.trim(),
      }).toList();
      
      questionData['match_pairs'] = matchPairs;
    } else if (_questionType == 'card_match') {
       // Inject default template for now
       questionData['options'] = {
        'buckets': [
          {'id': 'ease', 'label': 'Ease', 'icon': 'checklist', 'color': 'blue'},
          {'id': 'delight', 'label': 'Delight', 'icon': 'star', 'color': 'gold'}
        ],
        'cards': [
          {'id': 'c1', 'text': 'Clear process explanation', 'correct_bucket': 'ease'},
          {'id': 'c2', 'text': 'Quick resolution of issue', 'correct_bucket': 'ease'},
          {'id': 'c3', 'text': 'Thoughtful surprise element', 'correct_bucket': 'delight'},
          {'id': 'c4', 'text': 'Memorable experience moment', 'correct_bucket': 'delight'}
        ]
      };
    }

    await Supabase.instance.client.from('questions').insert(questionData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question added successfully!')),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      String errorMsg = 'Error saving question: $e';
      if (e.toString().contains('relation "questions" does not exist')) {
        errorMsg = 'Error: "question_bank" table missing in database.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    for (var pair in _matchPairs) {
      pair['left']!.dispose();
      pair['right']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Question'),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingPathways
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pathway Selection
                    DropdownButtonFormField<Pathway>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Pathway',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.route),
                      ),
                      value: _selectedPathway,
                      items: _pathways.map((pathway) {
                        return DropdownMenuItem(
                          value: pathway,
                          child: Text(
                            pathway.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) _loadLevels(value);
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Level Selection
                    if (_selectedPathway != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isLoadingLevels
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ))
                              : _levels.isEmpty 
                                  ? Center(
                                      child: Column(
                                        children: [
                                          const Text(
                                            'No levels found for this pathway.',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.add_task),
                                            label: const Text('Generate Default Levels'),
                                            onPressed: _generateDefaultLevels,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : DropdownButtonFormField<PathwayLevel>(
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Select Level',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.layers),
                                      ),
                                      value: _selectedLevel,
                                      hint: const Text('Tap to select level'),
                                      items: _levels.map((level) {
                                        return DropdownMenuItem<PathwayLevel>(
                                          value: level,
                                          child: Text(
                                            '${level.levelNumber} - ${level.levelName}',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        debugPrint("Level selected: ${value?.levelName}");
                                        setState(() => _selectedLevel = value);
                                      },
                                      validator: (v) => v == null ? 'Required' : null,
                                    ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Question Type Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Question Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.quiz),
                      ),
                      value: _questionType,
                      items: [
                        DropdownMenuItem(
                          value: 'card_match',
                          child: Text('Card Match Game'),
                        ),
                        DropdownMenuItem(
                          value: 'multiple_choice',
                          child: Text('Multiple Choice'),
                        ),
                        DropdownMenuItem(
                          value: 'match_following',
                          child: Text('Match the Following'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _questionType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Conditional UI based on question type
                    if (_questionType == 'multiple_choice') ...[
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Options
                      const Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                groupValue: _correctDisplayIndex,
                                onChanged: (val) {
                                  setState(() => _correctDisplayIndex = val!);
                                },
                                activeColor: Colors.green,
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _optionControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Option ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                        'Select the correct answer by clicking the radio button',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      // Match the Following UI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Match Pairs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_matchPairs.length < 6)
                            ElevatedButton.icon(
                              onPressed: _addMatchPair,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Pair'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B5CE7),
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_matchPairs.length, (index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pair ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_matchPairs.length > 3)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeMatchPair(index),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _matchPairs[index]['left'],
                                  decoration: const InputDecoration(
                                    labelText: 'Left Item',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.arrow_forward),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _matchPairs[index]['right'],
                                  decoration: const InputDecoration(
                                    labelText: 'Right Item (Match)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.check_circle_outline),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                        'Add 3-6 pairs. Users will match left items to right items.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498DB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Save Question',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
