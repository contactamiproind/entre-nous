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

  // Sequence Builder Form Data
  final List<Map<String, dynamic>> _sequenceSentences = [];

  // Budget Simulation Form Data
  final List<Map<String, dynamic>> _budgetDepartments = [];
  final TextEditingController _totalBudgetController = TextEditingController(text: '10000');

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

  void _addSequenceSentence() {
    setState(() {
      _sequenceSentences.add({
        'id': _sequenceSentences.length + 1,
        'controller': TextEditingController(),
        'position': _sequenceSentences.length + 1,
      });
    });
  }

  void _removeSequenceSentence(int index) {
    if (_sequenceSentences.length > 3) {
      setState(() {
        _sequenceSentences[index]['controller']!.dispose();
        _sequenceSentences.removeAt(index);
        // Renumber positions
        for (int i = 0; i < _sequenceSentences.length; i++) {
          _sequenceSentences[i]['id'] = i + 1;
          _sequenceSentences[i]['position'] = i + 1;
        }
      });
    }
  }

  void _addBudgetDepartment() {
    setState(() {
      _budgetDepartments.add({
        'id': _budgetDepartments.length + 1,
        'name': TextEditingController(),
        'amount': TextEditingController(),
      });
    });
  }

  void _removeBudgetDepartment(int index) {
    if (_budgetDepartments.length > 2) {
      setState(() {
        _budgetDepartments[index]['name']!.dispose();
        _budgetDepartments[index]['amount']!.dispose();
        _budgetDepartments.removeAt(index);
        // Renumber IDs
        for (int i = 0; i < _budgetDepartments.length; i++) {
          _budgetDepartments[i]['id'] = i + 1;
        }
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
    if (_questionType == 'sequence_builder') dbType = 'sequence_builder';
    if (_questionType == 'simulation') dbType = 'simulation';
    
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
     } else if (_questionType == 'sequence_builder') {
       final sentences = [];
       for (int i = 0; i < _sequenceSentences.length; i++) {
         final text = _sequenceSentences[i]['controller']!.text.trim();
         if (text.isNotEmpty) {
           sentences.add({'id': i + 1, 'text': text, 'correct_position': i + 1});
         }
       }
       if (sentences.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one sentence'), backgroundColor: Colors.red));
         setState(() => _isSaving = false);
         return;
       }
       questionData['options'] = sentences;
       debugPrint('📤 Sequence Builder sentences: $sentences');
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
    } else if (_questionType == 'simulation') {
      // Budget Simulation save logic
      if (_budgetDepartments.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least 2 departments'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Validate total budget
      final totalBudget = int.tryParse(_totalBudgetController.text.trim());
      if (totalBudget == null || totalBudget <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid total budget'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Build departments list and validate
      final departments = [];
      int totalAllocated = 0;

      for (int i = 0; i < _budgetDepartments.length; i++) {
        final dept = _budgetDepartments[i];
        final name = dept['name']!.text.trim();
        final amountStr = dept['amount']!.text.trim();

        if (name.isEmpty || amountStr.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please fill all fields for department ${i + 1}'), backgroundColor: Colors.red),
          );
          setState(() => _isSaving = false);
          return;
        }

        final amount = int.tryParse(amountStr);
        if (amount == null || amount < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid amount for $name'), backgroundColor: Colors.red),
          );
          setState(() => _isSaving = false);
          return;
        }

        totalAllocated += amount;
        departments.add({
          'id': i + 1,
          'name': name,
          'correct_amount': amount,
        });
      }

      // Validate that total allocated equals total budget
      if (totalAllocated != totalBudget) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Department amounts ($totalAllocated) must equal total budget ($totalBudget)'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Save budget simulation data
      questionData['options'] = {
        'total_budget': totalBudget,
        'departments': departments,
      };

      debugPrint('📤 Budget Simulation data: ${questionData['options']}');
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
    for (var sentence in _sequenceSentences) {
      sentence['controller']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Add New Question'),
        backgroundColor: const Color(0xFFF4EF8B),
        foregroundColor: Colors.black,
      ),
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
                                DropdownMenuItem(
                                  value: 'sequence_builder',
                                  child: Text('Sequence Builder'),
                                ),
                                DropdownMenuItem(
                                  value: 'simulation',
                                  child: Text('Budget Simulation'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _questionType = value;
                                    // Initialize sequence builder with 3 default sentences
                                    if (value == 'sequence_builder' && _sequenceSentences.isEmpty) {
                                      for (int i = 0; i < 3; i++) {
                                        _sequenceSentences.add({
                                          'id': i + 1,
                                          'controller': TextEditingController(),
                                          'position': i + 1,
                                        });
                                      }
                                    }
                                    // Initialize budget simulation with 3 default departments
                                    if (value == 'simulation' && _budgetDepartments.isEmpty) {
                                      for (int i = 0; i < 3; i++) {
                                        _budgetDepartments.add({
                                          'id': i + 1,
                                          'name': TextEditingController(),
                                          'amount': TextEditingController(),
                                        });
                                      }
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Title (for all question types)
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.title),
                              ),
                              maxLines: _questionType == 'sequence_builder' ? 1 : null,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 8),

                            // Description (for all question types)
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: _questionType == 'sequence_builder' ? 1 : 3,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 8),

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
                                backgroundColor: const Color(0xFF3B82F6),
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
                    ] else if (_questionType == 'sequence_builder') ...[
                      // Sequence Builder UI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sentences (in correct order)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_sequenceSentences.length < 9)
                            ElevatedButton.icon(
                              onPressed: _addSequenceSentence,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(_sequenceSentences.length, (index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BCD4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sequenceSentences[index]['controller'],
                                    decoration: InputDecoration(
                                      labelText: 'Sentence ${index + 1}',
                                      border: const OutlineInputBorder(),
                                      hintText: 'Enter sentence',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      isDense: true,
                                    ),
                                    maxLines: 1,
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                if (_sequenceSentences.length > 3)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _removeSequenceSentence(index),
                                    tooltip: 'Remove',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Text(
                        'Add 3-9 sentences in order. Users drag numbers to match.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (_questionType == 'simulation') ...[
                      // Budget Simulation UI
                      const Text(
                        'Budget Configuration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Total Budget Field
                      TextFormField(
                        controller: _totalBudgetController,
                        decoration: const InputDecoration(
                          labelText: 'Total Budget',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          hintText: '10000',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Departments Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Departments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_budgetDepartments.length < 10)
                            ElevatedButton.icon(
                              onPressed: _addBudgetDepartment,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Department'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Department Cards
                      ...List.generate(_budgetDepartments.length, (index) {
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
                                      'Department ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (_budgetDepartments.length > 2)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeBudgetDepartment(index),
                                        tooltip: 'Remove department',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _budgetDepartments[index]['name'],
                                  decoration: const InputDecoration(
                                    labelText: 'Department Name',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., Marketing, HR, IT',
                                    prefixIcon: Icon(Icons.business),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _budgetDepartments[index]['amount'],
                                  decoration: const InputDecoration(
                                    labelText: 'Correct Amount',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., 2000',
                                    prefixIcon: Icon(Icons.money),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    if (int.tryParse(v.trim()) == null) return 'Must be a number';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 8),
                      
                      // Tips Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Budget Simulation Tips',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Department amounts must equal total budget\n'
                              '• Add 2-10 departments\n'
                              '• Players drag budget amounts to departments',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
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
                                backgroundColor: const Color(0xFF3B82F6),
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

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8D96F),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.black)
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
