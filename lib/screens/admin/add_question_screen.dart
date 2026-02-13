import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/game_types.dart';
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
  Pathway? _selectedPathway;
  PathwayLevel? _selectedLevel;
  bool _isLoadingPathways = true;
  bool _isSaving = false;

  // Question Type
  String? _questionType; // nullable to show hint
  
  // Question Level
  int _selectedQuestionLevel = 1; // default to level 1
  
  // Subcategory
  String? _selectedSubcategory;

  // Title and Description
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController(text: '10');

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
    });

    try {
      await _pathwayService.getPathwayLevels(pathway.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading levels: $e')),
        );
      }
    }
  }

  Future<void> _generateDefaultLevels() async {
    if (_selectedPathway == null) return;
    
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
      }
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate based on question type
    if (_questionType == GameType.matchFollowing) {
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
      // Use the selected question level
      int levelNumber = _selectedQuestionLevel;

    // Map UI types to DB types using centralized mapping
    final String dbType = GameTypeDbMapping.toDbType(_questionType ?? 'mcq');
    
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
      'level': levelNumber,
      'points': int.parse(_pointsController.text.trim()),
      'created_at': DateTime.now().toIso8601String(),
    };
    
    // Only add level_id if a level is selected
    if (_selectedLevel != null) {
      questionData['level_id'] = _selectedLevel!.id;
    }

    if (_questionType == GameType.multipleChoice) {
      // Prepare options array with is_correct flags
      final options = _optionControllers.asMap().entries.map((entry) {
        return {
          'text': entry.value.text.trim(),
          'is_correct': entry.key == _correctDisplayIndex,
        };
      }).toList();
      
      questionData['options'] = options;
      questionData['correct_answer'] = _optionControllers[_correctDisplayIndex].text.trim();
    } else if (_questionType == GameType.matchFollowing) {
      // Prepare match pairs
      final matchPairs = _matchPairs.map((pair) => {
        'left': pair['left']!.text.trim(),
        'right': pair['right']!.text.trim(),
      }).toList();
      
      questionData['options'] = matchPairs;
    } else if (_questionType == GameType.cardMatch) {
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
     } else if (_questionType == GameType.sequenceBuilder) {
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
     } else if (_questionType == GameType.scenarioDecision) {
      // Prepare options array with is_correct flags (same as multiple choice)
      final options = _optionControllers.asMap().entries.map((entry) {
        return {
          'text': entry.value.text.trim(),
          'is_correct': entry.key == _correctDisplayIndex,
        };
      }).toList();
      
      questionData['options'] = options;
      questionData['correct_answer'] = _optionControllers[_correctDisplayIndex].text.trim();
    } else if (_questionType == GameType.simulation) {
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
            'level_name': levelNumber.toString(), // Use levelNumber as level_name
            'question_text': _titleController.text.trim(),
            'question_type': _questionType,
            'level': levelNumber,
            'category': 'Orientation',
            'subcategory': 'Vision',
            'points': int.parse(_pointsController.text.trim()),
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
    _pointsController.dispose();
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

  /// Compact input decoration matching our standard
  InputDecoration _inputDeco(String label, {IconData? icon, String? suffix, String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF1A2F4B)),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      filled: true,
      fillColor: Colors.white.withOpacity(0.7),
      prefixIcon: icon != null ? Icon(icon, size: 16, color: const Color(0xFF1A2F4B)) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      suffixText: suffix,
      suffixStyle: const TextStyle(fontSize: 11, color: Color(0xFF1A2F4B)),
    );
  }

  /// Compact section header
  Widget _sectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2F4B))),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Small add button
  Widget _addButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF9E6), Color(0xFFF4EF8B), Color(0xFFE8D96F)],
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
                    const Expanded(
                      child: Text(
                        'Add Question',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A2F4B)),
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: _isLoadingPathways
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Department
                              DropdownButtonFormField<Pathway>(
                                isExpanded: true,
                                decoration: _inputDeco('Department', icon: Icons.business),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF1A2F4B)),
                                value: _selectedPathway,
                                items: _pathways.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (v) { if (v != null) _loadLevels(v); },
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 8),

                              // Type
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: _inputDeco('Type', icon: Icons.quiz),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF1A2F4B)),
                                value: _questionType,
                                hint: const Text('Select type', style: TextStyle(fontSize: 12)),
                                items: const [
                                  DropdownMenuItem(value: GameType.multipleChoice, child: Text('Multiple Choice', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: GameType.matchFollowing, child: Text('Match Following', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: GameType.cardMatch, child: Text('Card Match', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: GameType.scenarioDecision, child: Text('Scenario Decision', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: GameType.sequenceBuilder, child: Text('Sequence Builder', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: GameType.simulation, child: Text('Budget Simulation', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _questionType = value;
                                      if (value == GameType.sequenceBuilder && _sequenceSentences.isEmpty) {
                                        for (int i = 0; i < 3; i++) {
                                          _sequenceSentences.add({'id': i + 1, 'controller': TextEditingController(), 'position': i + 1});
                                        }
                                      }
                                      if (value == GameType.simulation && _budgetDepartments.isEmpty) {
                                        for (int i = 0; i < 3; i++) {
                                          _budgetDepartments.add({'id': i + 1, 'name': TextEditingController(), 'amount': TextEditingController()});
                                        }
                                      }
                                    });
                                  }
                                },
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 8),

                              // Row 2: Level + Points
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      decoration: _inputDeco('Level', icon: Icons.stairs),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF1A2F4B)),
                                      value: _selectedQuestionLevel,
                                      items: const [
                                        DropdownMenuItem(value: 1, child: Text('Level 1', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 2, child: Text('Level 2', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 3, child: Text('Level 3', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 4, child: Text('Level 4', style: TextStyle(fontSize: 12))),
                                      ],
                                      onChanged: (v) { if (v != null) setState(() => _selectedQuestionLevel = v); },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      controller: _pointsController,
                                      decoration: _inputDeco('Points', icon: Icons.star, suffix: 'pts'),
                                      style: const TextStyle(fontSize: 12),
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Required';
                                        if (int.tryParse(v) == null) return 'Number';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Title
                              TextFormField(
                                controller: _titleController,
                                decoration: _inputDeco('Title', icon: Icons.title),
                                style: const TextStyle(fontSize: 12),
                                maxLines: _questionType == GameType.sequenceBuilder ? 1 : null,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 8),

                              // Description
                              TextFormField(
                                controller: _descriptionController,
                                decoration: _inputDeco('Description', icon: Icons.description),
                                style: const TextStyle(fontSize: 12),
                                maxLines: _questionType == GameType.sequenceBuilder ? 1 : 2,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 4),

                              // === Type-specific sections ===
                              if (_questionType == GameType.multipleChoice || _questionType == GameType.scenarioDecision) ...[
                                _sectionHeader(_questionType == GameType.scenarioDecision ? 'Decision Options' : 'Options'),
                                ...List.generate(4, (i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          child: Radio<int>(
                                            value: i,
                                            groupValue: _correctDisplayIndex,
                                            onChanged: (val) => setState(() => _correctDisplayIndex = val!),
                                            activeColor: const Color(0xFF10B981),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _optionControllers[i],
                                            decoration: _inputDeco('Option ${i + 1}'),
                                            style: const TextStyle(fontSize: 12),
                                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                Text('Tap radio to mark correct answer', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                              ] else if (_questionType == GameType.matchFollowing) ...[
                                _sectionHeader('Match Pairs', trailing: _matchPairs.length < 6 ? _addButton('Pair', _addMatchPair) : null),
                                ...List.generate(_matchPairs.length, (i) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    elevation: 0.5,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22, height: 22,
                                            decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                            child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)))),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _matchPairs[i]['left'],
                                              decoration: _inputDeco('Left item'),
                                              style: const TextStyle(fontSize: 11),
                                              validator: (v) => v == null || v.trim().isEmpty ? '' : null,
                                            ),
                                          ),
                                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey)),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _matchPairs[i]['right'],
                                              decoration: _inputDeco('Right match'),
                                              style: const TextStyle(fontSize: 11),
                                              validator: (v) => v == null || v.trim().isEmpty ? '' : null,
                                            ),
                                          ),
                                          if (_matchPairs.length > 3)
                                            InkWell(
                                              onTap: () => _removeMatchPair(i),
                                              child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close, size: 14, color: Colors.red.shade400)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                Text('3-6 pairs. Users match left to right.', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                              ] else if (_questionType == GameType.cardMatch) ...[
                                _sectionHeader('Card Pairs', trailing: _cardPairs.length < 8 ? _addButton('Pair', _addCardPair) : null),
                                ...List.generate(_cardPairs.length, (i) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    elevation: 0.5,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22, height: 22,
                                            decoration: BoxDecoration(color: const Color(0xFFFBBF24).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                            child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFFBBF24)))),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _cardPairs[i]['card1'],
                                              decoration: _inputDeco('Card 1'),
                                              style: const TextStyle(fontSize: 11),
                                              validator: (v) => v == null || v.trim().isEmpty ? '' : null,
                                            ),
                                          ),
                                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.swap_horiz, size: 12, color: Colors.grey)),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _cardPairs[i]['card2'],
                                              decoration: _inputDeco('Card 2'),
                                              style: const TextStyle(fontSize: 11),
                                              validator: (v) => v == null || v.trim().isEmpty ? '' : null,
                                            ),
                                          ),
                                          if (_cardPairs.length > 3)
                                            InkWell(
                                              onTap: () => _removeCardPair(i),
                                              child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close, size: 14, color: Colors.red.shade400)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                Text('3-8 pairs. Players flip cards to find matches.', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                              ] else if (_questionType == GameType.sequenceBuilder) ...[
                                _sectionHeader('Sentences (correct order)', trailing: _sequenceSentences.length < 9 ? _addButton('Add', _addSequenceSentence) : null),
                                ...List.generate(_sequenceSentences.length, (i) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    elevation: 0.5,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22, height: 22,
                                            decoration: BoxDecoration(color: const Color(0xFF00BCD4).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                            child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF00BCD4)))),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _sequenceSentences[i]['controller'],
                                              decoration: _inputDeco('Sentence ${i + 1}'),
                                              style: const TextStyle(fontSize: 11),
                                              maxLines: 1,
                                              validator: (v) => v == null || v.trim().isEmpty ? '' : null,
                                            ),
                                          ),
                                          if (_sequenceSentences.length > 3)
                                            InkWell(
                                              onTap: () => _removeSequenceSentence(i),
                                              child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close, size: 14, color: Colors.red.shade400)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                Text('3-9 sentences. Users drag to reorder.', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                              ] else if (_questionType == GameType.simulation) ...[
                                _sectionHeader('Budget Configuration'),
                                TextFormField(
                                  controller: _totalBudgetController,
                                  decoration: _inputDeco('Total Budget', icon: Icons.attach_money, hint: '10000'),
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    if (int.tryParse(v.trim()) == null) return 'Number';
                                    return null;
                                  },
                                ),
                                _sectionHeader('Departments', trailing: _budgetDepartments.length < 10 ? _addButton('Dept', _addBudgetDepartment) : null),
                                ...List.generate(_budgetDepartments.length, (i) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    elevation: 0.5,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22, height: 22,
                                            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                            child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF10B981)))),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _budgetDepartments[i]['name'],
                                              decoration: _inputDeco('Name', hint: 'Marketing'),
                                              style: const TextStyle(fontSize: 11),
                                              validator: (v) => v == null || v.trim().isEmpty ? '' : null,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          SizedBox(
                                            width: 80,
                                            child: TextFormField(
                                              controller: _budgetDepartments[i]['amount'],
                                              decoration: _inputDeco('Amount'),
                                              style: const TextStyle(fontSize: 11),
                                              keyboardType: TextInputType.number,
                                              validator: (v) {
                                                if (v == null || v.trim().isEmpty) return '';
                                                if (int.tryParse(v.trim()) == null) return '';
                                                return null;
                                              },
                                            ),
                                          ),
                                          if (_budgetDepartments.length > 2)
                                            InkWell(
                                              onTap: () => _removeBudgetDepartment(i),
                                              child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close, size: 14, color: Colors.red.shade400)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                Text('Amounts must equal total budget.', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                              ],

                              const SizedBox(height: 20),
                              // Save button
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveQuestion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 1,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Save Question', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
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
