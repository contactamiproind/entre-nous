import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/pathway.dart';
import '../../services/pathway_service.dart';

class AddQuestionScreen extends StatefulWidget {
  final String? departmentId;
  
  const AddQuestionScreen({super.key, this.departmentId});

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
  String? _questionType; // nullable to show hint
  
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

  // Card Match (Flip Card) Form Data
  final List<Map<String, TextEditingController>> _cardPairs = [];

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

  void _addCardPair() {
    if (_cardPairs.length < 8) {
      setState(() {
        _cardPairs.add({
          'card1': TextEditingController(),
          'card2': TextEditingController(),
        });
      });
    }
  }

  void _removeCardPair(int index) {
    if (_cardPairs.length > 3) {
      setState(() {
        _cardPairs[index]['card1']!.dispose();
        _cardPairs[index]['card2']!.dispose();
        _cardPairs.removeAt(index);
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
    // Initialize with 3 card pairs
    for (int i = 0; i < 3; i++) {
      _addCardPair();
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final pathways = await _pathwayService.getAllPathways();
      setState(() {
        _pathways = pathways;
        _isLoadingPathways = false;
        
        // Pre-select department if departmentId is provided
        if (widget.departmentId != null) {
          _selectedPathway = pathways.firstWhere(
            (p) => p.id == widget.departmentId,
            orElse: () => pathways.first,
          );
          // Load levels for pre-selected department
          _loadLevels(_selectedPathway!);
        }
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
    String dbType = _questionType ?? 'mcq';
    if (_questionType == 'multiple_choice') dbType = 'mcq';
    if (_questionType == 'match_following') dbType = 'match';
    if (_questionType == 'scenario_decision') dbType = 'scenario_decision';
    if (_questionType == 'card_match') dbType = 'card_match';
    
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
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type_id': typeRes['id'], // Use type_id instead of question_type
      'difficulty': difficulty,
      'points': 10,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    // Only add level_id if a level is selected
    if (_selectedLevel != null) {
      questionData['level_id'] = _selectedLevel!.id;
    }

    if (_questionType == 'multiple_choice') {
      // Prepare options array with is_correct flags
      final options = _optionControllers.asMap().entries.map((entry) {
        return {
          'text': entry.value.text.trim(),
          'is_correct': entry.key == _correctDisplayIndex,
        };
      }).toList();
      
      questionData['options'] = options;
      questionData['correct_answer'] = _optionControllers[_correctDisplayIndex].text.trim();
    } else if (_questionType == 'match_following') {
      // Prepare match pairs
      final matchPairs = _matchPairs.map((pair) => {
        'left': pair['left']!.text.trim(),
        'right': pair['right']!.text.trim(),
      }).toList();
      
      questionData['match_pairs'] = matchPairs;
    } else if (_questionType == 'card_match') {
       // Card Flip (Memory Match) game format
       // Validate card pairs
       if (_cardPairs.length < 3) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please add at least 3 card pairs')),
         );
         return;
       }
       
       // Check if all pairs are filled
       for (var pair in _cardPairs) {
         if (pair['card1']!.text.trim().isEmpty || pair['card2']!.text.trim().isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Please fill all card pairs')),
           );
           return;
         }
       }
       
       // Convert to pairs format for CardFlipGameWidget
       // Store in options field as array of pair objects
       final pairs = [];
       for (int i = 0; i < _cardPairs.length; i++) {
         pairs.add({
           'id': i + 1,
           'question': _cardPairs[i]['card1']!.text.trim(),
           'answer': _cardPairs[i]['card2']!.text.trim(),
         });
       }
       
       questionData['options'] = pairs;
    } else if (_questionType == 'scenario_decision') {
      // Prepare options array with is_correct flags (same as multiple choice)
      final options = _optionControllers.asMap().entries.map((entry) {
        return {
          'text': entry.value.text.trim(),
          'is_correct': entry.key == _correctDisplayIndex,
        };
      }).toList();
      
      questionData['options'] = options;
      questionData['correct_answer'] = _optionControllers[_correctDisplayIndex].text.trim();
    }

    // Debug: Print the data being sent
    debugPrint('📤 Saving Card Match question data:');
    debugPrint('   Type: ${questionData['type_id']}');
    debugPrint('   Options: ${questionData['options']}');
    debugPrint('   Options Data: ${questionData['options_data']}');
    debugPrint('   Full data: $questionData');

    final insertedQuestion = await Supabase.instance.client
        .from('questions')
        .insert(questionData)
        .select()
        .single();

    // AUTO-ASSIGNMENT: Create usr_progress entries for all users with this department
    try {
      final questionId = insertedQuestion['id'];
      final deptId = _selectedPathway!.id;
      final levelNumber = _selectedLevel?.levelNumber ?? 1; // Default to 1 if no level selected
      
      debugPrint('🔄 Starting auto-assignment for question $questionId');
      
      // Get all users who have this department assigned
      final usersWithDept = await Supabase.instance.client
          .from('usr_dept')
          .select('id, user_id')
          .eq('dept_id', deptId);
      
      debugPrint('👥 Found ${usersWithDept.length} users with this department');
      
      if (usersWithDept.isNotEmpty) {
        // Create usr_progress entries for each user
        final progressEntries = usersWithDept.map((userDept) {
          return {
            'user_id': userDept['user_id'],
            'usr_dept_id': userDept['id'], // Link to usr_dept
            'question_id': questionId,
            'dept_id': deptId,
            'level_number': levelNumber,
            'level_name': difficulty, // Use difficulty as level_name
            'question_text': _titleController.text.trim(),
            'question_type': _questionType,
            'difficulty': difficulty,
            'category': 'Orientation',
            'subcategory': 'Vision',
            'points': 10,
            'status': 'pending',
            'score_earned': 0,
            'attempt_count': 0,
            'flagged_for_review': false,
          };
        }).toList();
        
        await Supabase.instance.client
            .from('usr_progress')
            .insert(progressEntries);
        
        debugPrint('✅ Auto-assigned question to ${usersWithDept.length} users');
      } else {
        debugPrint('⚠️ No users found with this department');
      }
    } catch (e) {
      debugPrint('⚠️ Auto-assignment failed: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      // Don't fail the whole operation if auto-assignment fails
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question added and assigned to users successfully!')),
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
    for (var pair in _cardPairs) {
      pair['card1']!.dispose();
      pair['card2']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Add New Question'),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6EC1E4),
              Color(0xFF9BA8E8),
              Color(0xFFE8A8D8),
            ],
          ),
        ),
        child: _isLoadingPathways
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
                              : _levels.isNotEmpty 
                                  ? DropdownButtonFormField<PathwayLevel>(
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
                                    )
                                  : const SizedBox.shrink(),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Question Type Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.quiz),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _questionType,
                      hint: const Text('Question Type'),
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
                        DropdownMenuItem(
                          value: 'scenario_decision',
                          child: Text('Scenario Decision'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _questionType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Title (for all question types)
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

                    // Description (for all question types)
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

                    // Conditional UI based on question type
                    if (_questionType == 'multiple_choice') ...[
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
                    ] else if (_questionType == 'scenario_decision') ...[
                      // Scenario Decision UI
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Scenario Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.psychology),
                        ),
                        maxLines: 3,
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
                      
                      const Text(
                        'Decision Options',
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
                        'Select the best decision (correct answer)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (_questionType == 'card_match') ...[
                      // Card Match (Flip Card Memory Game) UI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Card Pairs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_cardPairs.length < 8)
                            ElevatedButton.icon(
                              onPressed: _addCardPair,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Pair'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_cardPairs.length, (index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
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
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (_cardPairs.length > 3)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeCardPair(index),
                                        tooltip: 'Remove pair',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _cardPairs[index]['card1'],
                                  decoration: const InputDecoration(
                                    labelText: 'Card 1 (e.g., 🥑 Avocado Toast)',
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter text or emoji',
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _cardPairs[index]['card2'],
                                  decoration: const InputDecoration(
                                    labelText: 'Card 2 (e.g., Healthy Breakfast)',
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter matching text',
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
                        'Add 3-8 pairs. Players flip cards to find matching pairs by memory.',
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
        ),
    );
  }
}
