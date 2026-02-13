import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/pathway.dart';
import '../../models/user_assignment.dart';
import '../../services/pathway_service.dart';
import '../../services/assignment_service.dart';
import '../../services/progress_service.dart';
import 'profile_actions_screen.dart';
import 'pathway_detail_screen.dart';
import '../end_game/end_game_screen.dart';
import 'quiz_screen.dart';

class EnhancedUserDashboard extends StatefulWidget {
  const EnhancedUserDashboard({super.key});

  @override
  State<EnhancedUserDashboard> createState() => _EnhancedUserDashboardState();
}

class _EnhancedUserDashboardState extends State<EnhancedUserDashboard> with WidgetsBindingObserver {
  final PathwayService _pathwayService = PathwayService();
  final AssignmentService _assignmentService = AssignmentService();
  final ProgressService _progressService = ProgressService();

  Map<String, dynamic>? _userProgress;
  Map<String, dynamic>? _userProfile;
  List<Pathway> _pathways = [];
  List<UserAssignment> _assignments = [];
  Pathway? _currentPathway;
  List<PathwayLevel> _currentLevels = [];
  bool _isLoading = true;
  String? _userId;
  String? _userEmail;
  String _userName = 'Explorer';
  String _userAvatar = '👤';
  int _userLevel = 1;
  int _selectedIndex = 0;
  int _totalPoints = 0;
  String _lastLoginAgo = '';
  
  // Motivational quotes rotated by day
  static const List<String> _quotes = [
    'Every expert was once a beginner.',
    'Small steps lead to big results.',
    'Learning is a journey, not a destination.',
    'Progress, not perfection.',
    'You\'re doing great — keep going!',
    'Knowledge is the best investment.',
    'One question at a time, one win at a time.',
  ];
  
  // Category progress tracking for Continue feature
  Map<String, Map<String, dynamic>> _categoryProgress = {}; // category -> {total, answered, firstUnansweredIndex}
  
  // Raw usr_dept records for level-grouped display
  List<Map<String, dynamic>> _userDeptRecords = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app resumes (user returns from End Game)
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed, refreshing dashboard data...');
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      _userId = user.id;
      _userEmail = user.email;
      
      // Load user profile
      Map<String, dynamic>? profile;
      try {
        profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (profile != null) {
          _userName = profile['full_name'] ?? user.email?.split('@')[0] ?? 'Explorer';
          _userAvatar = profile['avatar_url'] ?? '👤';
          _userLevel = (profile['level'] as int?) ?? 1;
          // Compute last login ago from updated_at
          final updatedAt = profile['updated_at']?.toString();
          if (updatedAt != null) {
            final dt = DateTime.tryParse(updatedAt);
            if (dt != null) {
              final diff = DateTime.now().toUtc().difference(dt);
              if (diff.inMinutes < 1) {
                _lastLoginAgo = 'Just now';
              } else if (diff.inMinutes < 60) {
                _lastLoginAgo = '${diff.inMinutes}m ago';
              } else if (diff.inHours < 24) {
                _lastLoginAgo = '${diff.inHours}h ago';
              } else {
                _lastLoginAgo = '${diff.inDays}d ago';
              }
            }
          }
        } else {
          _userName = user.email?.split('@')[0] ?? 'Explorer';
          _userLevel = 1;
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
        _userName = user.email?.split('@')[0] ?? 'Explorer';
        _userLevel = 1;
      }
      
      // Skip orientation check - users can access any assigned department
      // Orientation is optional, not mandatory
      // final isOrientationCompleted = await _pathwayService.isOrientationCompleted(_userId!);
      // if (!isOrientationCompleted && mounted) {
      //   setState(() => _isLoading = false);
      //   _showOrientationRequiredDialog();
      //   return;
      // }
      
      // Load data in parallel for faster performance
      Map<String, dynamic>? progress;
      List<UserAssignment> assignments = [];
      List<Pathway> pathways = [];

      try {
        debugPrint('🔑 Loading data for user_id: $_userId');
        final results = await Future.wait<dynamic>([
          // 0: User Progress
          _progressService.getUserProgress(_userId!).catchError((e) {
            debugPrint('❌ Error getting user progress: $e');
            return null;
          }),
          // 1: Assignments
          _assignmentService.getUserAssignments(_userId!),
          // 2: Pathways
          _pathwayService.getAllPathways(),
          // 3: Total Points (User Progress + End Game)
          Future.wait([
             Supabase.instance.client
                .from('usr_progress')
                .select('question_id, score_earned')
                .eq('user_id', _userId!)
                .then((data) {
                  // Calculate points based on unique questions (max score per question)
                  final bestScores = <String, int>{};
                  for (var item in data as List) {
                    final qId = item['question_id'].toString();
                    final score = item['score_earned'] as int? ?? 0;
                    if (score > (bestScores[qId] ?? -1)) {
                      bestScores[qId] = score;
                    }
                  }
                  return bestScores.values.fold(0, (sum, score) => sum + score);
                }),
             Supabase.instance.client
                .from('end_game_assignments')
                .select('score')
                .eq('user_id', _userId!)
                .not('completed_at', 'is', null)
                .then((data) => (data as List).fold<int>(0, (sum, item) => sum + (item['score'] as int? ?? 0))),
          ]).then((results) => results.fold<int>(0, (sum, item) => sum + item))
            .catchError((e) {
              debugPrint('❌ Error calculating points: $e');
              return 0;
            }),
        ]);

        progress = results[0] as Map<String, dynamic>?;
        assignments = results[1] as List<UserAssignment>;
        pathways = results[2] as List<Pathway>;
        final totalPoints = results[3] as int;
        
        if (mounted) {
          setState(() => _totalPoints = totalPoints);
        }
      } catch (e) {
        debugPrint('Partial error loading data: $e');
      }

      Pathway? currentPathway;
      List<PathwayLevel> currentLevels = [];
      
      // Try to get pathway from progress first, fallback to user_pathway
      if (progress?['current_pathway_id'] != null) {
        try {
          currentPathway = await _pathwayService.getPathwayById(progress!['current_pathway_id']);
          if (currentPathway != null) {
            currentLevels = await _pathwayService.getPathwayLevels(currentPathway.id);
          }
        } catch (e) {
          debugPrint('Error loading pathway from progress: $e');
        }
      } else if (assignments.isNotEmpty) {
        // Fallback: Load from usr_dept (assignments)
        try {
          final firstAssignment = assignments.first;
          // Validate pathwayId is not empty and is a valid UUID format
          if (firstAssignment.pathwayId.isNotEmpty && 
              firstAssignment.pathwayId.length == 36 &&
              firstAssignment.pathwayId.contains('-')) {
            currentPathway = await _pathwayService.getPathwayById(firstAssignment.pathwayId);
            if (currentPathway != null) {
              currentLevels = await _pathwayService.getPathwayLevels(currentPathway.id);
            }
          } else {
            debugPrint('⚠️ Invalid pathwayId: "${firstAssignment.pathwayId}"');
          }
        } catch (e) {
          debugPrint('❌ ERROR loading pathway data: $e');
        }
      }
      
      // TEMPORARILY DISABLED: Pathway auto-assignment causing crashes
      // TODO: Debug and re-enable after fixing null safety issues
      // User must manually set pathway through Admin Dashboard
      /*
      if (currentPathway == null && assignments.isNotEmpty) {
        try {
          final firstAssignment = assignments.first;
          if (firstAssignment.pathwayId.isNotEmpty) {
            currentPathway = await _pathwayService.getPathwayById(firstAssignment.pathwayId);
            if (currentPathway != null) {
              currentLevels = await _pathwayService.getPathwayLevels(currentPathway.id);
            }
          }
        } catch (e) {
          debugPrint('Error loading pathway from assignment: $e');
        }
      }
      */
      debugPrint('📍 Pathway auto-assignment disabled. Current pathway: ${currentPathway?.title ?? "null"}');

      setState(() {
        _userProgress = progress;
        _userProfile = profile;
        _assignments = assignments;
        _pathways = pathways;
        _currentPathway = currentPathway;
        _currentLevels = currentLevels;
        _isLoading = false;
      });
      
      // Load category progress for Continue feature
      await _loadCategoryProgress();
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _loadCategoryProgress() async {
    if (_userId == null) return;
    try {
      // Get all departments assigned to this user from usr_dept (full records for level-grouped display)
      final userDeptsData = await Supabase.instance.client
          .from('usr_dept')
          .select('*, departments(id, title, category)')
          .eq('user_id', _userId!)
          .order('assigned_at', ascending: true);
      
      _userDeptRecords = List<Map<String, dynamic>>.from(userDeptsData);
      
      debugPrint('📊 Found ${userDeptsData.length} assigned departments for user');
      
      // Extract unique categories from assigned departments
      final assignedCategories = <String>{};
      for (final userDept in userDeptsData) {
        final dept = userDept['departments'];
        if (dept != null && dept['category'] != null) {
          assignedCategories.add(dept['category']);
        }
      }
      
      debugPrint('📋 Assigned categories from usr_dept: $assignedCategories');

      // Check for End Game assignment based on CURRENT LEVEL
      try {
        debugPrint('🔍 Checking End Game assignment for user: $_userId');
        
        // 1. Get user's highest level across departments
        final userLevelData = await Supabase.instance.client
            .from('usr_dept')
            .select('current_level')
            .eq('user_id', _userId!)
            .order('current_level', ascending: false)
            .limit(1)
            .maybeSingle();
            
        final int currentLevel = userLevelData != null ? (userLevelData['current_level'] as int) : 1;
        debugPrint('🔍 User is at Level $currentLevel. Checking for matching End Game...');

        // 2. Get the active End Game Config for this level
        final endGameConfig = await Supabase.instance.client
            .from('end_game_configs')
            .select('id')
            .eq('level', currentLevel)
            .eq('is_active', true)
            .maybeSingle();
            
        if (endGameConfig != null) {
          final endGameId = endGameConfig['id'];
          
          // 3. Get the assignment for THIS specific End Game
          final assignment = await Supabase.instance.client
              .from('end_game_assignments')
              .select('id, completed_at, assigned_at')
              .eq('user_id', _userId!)
              .eq('end_game_id', endGameId)
              .maybeSingle();
          
          if (assignment != null) {
            debugPrint('🎮 User has End Game assignment for Level $currentLevel!');
            debugPrint('🎮 Assignment details: $assignment');
            assignedCategories.add('End Game');
            
            final isCompleted = assignment['completed_at'] != null;
            
            // Initialize progress for End Game
            _categoryProgress['End Game'] = {
              'total': 1, 
              'answered': isCompleted ? 1 : 0, 
              'firstUnansweredIndex': 0, 
              'progress': isCompleted ? 1.0 : 0.0
            };
            debugPrint('✅ End Game added with progress: ${isCompleted ? "100%" : "0%"}');
          } else {
            debugPrint('❌ No assignment found for active End Game (Level $currentLevel)');
          }
        } else {
          debugPrint('❌ No active End Game config found for Level $currentLevel');
        }
      } catch (e) {
        debugPrint('❌ Error checking End Game assignment: $e');
      }
      
      // Build progress from usr_progress records grouped by actual level_number.
      // A single usr_dept may have questions at multiple levels, so we split them
      // into virtual records so the dashboard shows the correct level grouping.
      final List<Map<String, dynamic>> expandedRecords = [];

      for (final record in List<Map<String, dynamic>>.from(_userDeptRecords)) {
        final dept = record['departments'];
        final category = dept?['category'] as String?;
        if (category == null || category == 'End Game') continue;

        final usrDeptId = record['id'];

        // Fetch all usr_progress for this usr_dept, grouped by level_number
        List progressRecords = [];
        try {
          progressRecords = await Supabase.instance.client
              .from('usr_progress')
              .select('question_id, status, level_number, score_earned')
              .eq('usr_dept_id', usrDeptId)
              .order('created_at', ascending: true);
        } catch (e) {
          debugPrint('Error loading progress for $category: $e');
        }

        if (progressRecords.isEmpty) {
          // No progress records — keep original record as-is
          expandedRecords.add(record);
          continue;
        }

        // Group by level_number
        final Map<int, List<dynamic>> byLevel = {};
        for (final pr in progressRecords) {
          final lvl = pr['level_number'] is int ? pr['level_number'] as int : (record['current_level'] as int? ?? 1);
          byLevel.putIfAbsent(lvl, () => []);
          byLevel[lvl]!.add(pr);
        }

        if (byLevel.length <= 1) {
          // All questions at same level — use original record, just ensure current_level matches
          final actualLevel = byLevel.keys.first;
          final questions = byLevel[actualLevel]!;
          final totalQ = questions.length;
          final answeredQ = questions.where((p) => p['status'] == 'answered').length;
          final correctQ = questions.where((p) => p['status'] == 'answered' && (p['score_earned'] as int? ?? 0) > 0).length;
          final totalScore = questions.fold<int>(0, (sum, p) => sum + (p['score_earned'] as int? ?? 0));
          final maxScore = totalQ * 10;
          int firstUnanswered = 0;
          for (int i = 0; i < questions.length; i++) {
            if (questions[i]['status'] != 'answered') {
              firstUnanswered = i;
              break;
            }
          }
          final progressPct = totalQ > 0 ? answeredQ / totalQ : 0.0;
          _categoryProgress[category] = {
            'total': totalQ,
            'answered': answeredQ,
            'firstUnansweredIndex': firstUnanswered,
            'progress': progressPct,
            'level': actualLevel,
          };
          // Override current_level to the actual level from usr_progress
          final updatedRecord = Map<String, dynamic>.from(record);
          updatedRecord['current_level'] = actualLevel;
          updatedRecord['total_questions'] = totalQ;
          updatedRecord['answered_questions'] = answeredQ;
          updatedRecord['correct_answers'] = correctQ;
          updatedRecord['total_score'] = totalScore;
          updatedRecord['max_possible_score'] = maxScore;
          expandedRecords.add(updatedRecord);
          debugPrint('📊 $category L$actualLevel: $answeredQ/$totalQ (${(progressPct * 100).toStringAsFixed(0)}%)');
        } else {
          // Multiple levels — create a virtual record per level
          final sortedLevels = byLevel.keys.toList()..sort();
          for (final lvl in sortedLevels) {
            final questions = byLevel[lvl]!;
            final totalQ = questions.length;
            final answeredQ = questions.where((p) => p['status'] == 'answered').length;
            int firstUnanswered = 0;
            for (int i = 0; i < questions.length; i++) {
              if (questions[i]['status'] != 'answered') {
                firstUnanswered = i;
                break;
              }
            }
            final progressPct = totalQ > 0 ? answeredQ / totalQ : 0.0;

            // Store progress keyed by category+level to avoid overwriting
            final progressKey = '${category}_L$lvl';
            _categoryProgress[progressKey] = {
              'total': totalQ,
              'answered': answeredQ,
              'firstUnansweredIndex': firstUnanswered,
              'progress': progressPct,
              'level': lvl,
            };

            final correctQ = questions.where((p) => p['status'] == 'answered' && (p['score_earned'] as int? ?? 0) > 0).length;
            final totalScore = questions.fold<int>(0, (sum, p) => sum + (p['score_earned'] as int? ?? 0));
            final maxScore = totalQ * 10;

            // Create a virtual record that looks like a usr_dept record
            final virtualRecord = Map<String, dynamic>.from(record);
            virtualRecord['current_level'] = lvl;
            virtualRecord['total_questions'] = totalQ;
            virtualRecord['answered_questions'] = answeredQ;
            virtualRecord['correct_answers'] = correctQ;
            virtualRecord['total_score'] = totalScore;
            virtualRecord['max_possible_score'] = maxScore;
            expandedRecords.add(virtualRecord);
            debugPrint('📊 $category L$lvl: $answeredQ/$totalQ (${(progressPct * 100).toStringAsFixed(0)}%)');
          }
        }
      }

      // Replace _userDeptRecords with the expanded set
      _userDeptRecords = expandedRecords;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading category progress: $e');
    }
  }

  // Helper widget for home header stat chips (Completed, Points, Level)
  Widget _buildHomeStatChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
              ),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for mini stat chips (Attempted, Correct, Score)
  Widget _buildMiniStat(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 11, color: color),
                  const SizedBox(width: 3),
                  Text(
                    label,
                    style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get icon for each category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Orientation': return Icons.school_rounded;
      case 'Process': return Icons.settings_rounded;
      case 'SOP': return Icons.description_rounded;
      case 'Production': return Icons.factory_rounded;
      case 'Communication': return Icons.chat_rounded;
      case 'Ideation': return Icons.lightbulb_rounded;
      case 'Client Servicing': return Icons.support_agent_rounded;
      case 'Creative': return Icons.palette_rounded;
      default: return Icons.folder_rounded;
    }
  }

  // Helper method to get color for each category
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Orientation': return const Color(0xFFF4EF8B); // Yellow
      case 'Process': return const Color(0xFF3B82F6); // Blue
      case 'SOP': return const Color(0xFF10B981); // Green
      case 'Production': return const Color(0xFFEF4444); // Red
      case 'Communication': return const Color(0xFF8B5CF6); // Purple
      case 'Ideation': return const Color(0xFFF59E0B); // Orange
      case 'Client Servicing': return const Color(0xFF06B6D4); // Cyan
      case 'Creative': return const Color(0xFFEC4899); // Pink
      default: return Colors.grey;
    }
  }

  // Helper method to get description for each category
  String _getCategoryDescription(String category) {
    switch (category) {
      case 'Orientation': return 'Get started with the basics';
      case 'Process': return 'Standard workflows and procedures';
      case 'SOP': return 'Standard Operating Procedures';
      case 'Production': return 'Production workflows and processes';
      case 'Communication': return 'Communication skills and strategies';
      case 'Ideation': return 'Creative thinking and ideation';
      case 'Client Servicing': return 'Client management and servicing';
      case 'Creative': return 'Creative design and execution';
      default: return 'Department pathway';
    }
  }

  // Helper method to determine if a category is locked
  bool _isCategoryLocked(String category) {
    // General departments: sequential locking
    if (category == 'Orientation') return false; // Always unlocked
    
    if (category == 'Process') {
      final orientProgress = _categoryProgress['Orientation'];
      if (orientProgress == null) return true;
      
      final orientLevel = orientProgress['level'] ?? 1;
      final orientPerc = orientProgress['progress'] ?? 0.0;
      final processLevel = _categoryProgress['Process']?['level'] ?? 1;

      // Unlocked if Orientation is at a HIGHER level, 
      // or if at the SAME level and Orientation is complete.
      if (orientLevel > processLevel) return false;
      if (orientLevel == processLevel) return orientPerc < 1.0;
      return true; // Orientation behind Process (shouldn't happen)
    }
    
    if (category == 'SOP') {
      bool processLocked = _isCategoryLocked('Process');
      final processProgress = _categoryProgress['Process'];
      if (processProgress == null || processLocked) return true;

      final processLevel = processProgress['level'] ?? 1;
      final processPerc = processProgress['progress'] ?? 0.0;
      final sopLevel = _categoryProgress['SOP']?['level'] ?? 1;

      if (processLevel > sopLevel) return false;
      if (processLevel == sopLevel) return processPerc < 1.0;
      return true;
    }
    
    // Specific departments: must complete all General departments first
    final orientationLocked = _isCategoryLocked('Orientation');
    final processLocked = _isCategoryLocked('Process');
    final sopLocked = _isCategoryLocked('SOP');

    final orientProgress = _categoryProgress['Orientation'];
    final procProgress = _categoryProgress['Process'];
    final sProgress = _categoryProgress['SOP'];

    if (orientProgress == null || procProgress == null || sProgress == null) return true;

    // Check if any general category is locked
    if (orientationLocked || processLocked || sopLocked) return true;
    
    // Check if any general category is incomplete at the current global level
    // This is a bit simplified, but ensures sequential flow
    if (orientProgress['progress'] < 1.0 || procProgress['progress'] < 1.0 || sProgress['progress'] < 1.0) {
      return true;
    }
    
    return false;
  }

  // Helper method to build dynamic category list items for Categories tab
  List<Widget> _buildDynamicCategoryListItems() {
    final List<Widget> items = [];
    
    // Define the order: General departments first, then specific departments
    final generalOrder = ['Orientation', 'Process', 'SOP'];
    final List<String> orderedCategories = [];
    
    // Add General departments in order (if assigned)
    for (final category in generalOrder) {
      if (_categoryProgress.containsKey(category)) {
        orderedCategories.add(category);
      }
    }
    
    // Add specific departments (all others)
    for (final category in _categoryProgress.keys) {
      if (!generalOrder.contains(category) && category != 'End Game') {
        orderedCategories.add(category);
      }
    }
    
    // Build list items for each category
    for (int i = 0; i < orderedCategories.length; i++) {
      final category = orderedCategories[i];
      final progress = _categoryProgress[category]?['progress'] ?? 0.0;
      final isLocked = _isCategoryLocked(category);
      final isCurrent = !isLocked && progress < 1.0;
      
      items.add(
        _buildCategoryListItem(
          category: category,
          subcategory: null,
          icon: _getCategoryIcon(category),
          color: _getCategoryColor(category),
          progress: progress,
          isLocked: isLocked,
          isCurrent: isCurrent,
        ),
      );
      
      // Add spacing between items (except after the last one)
      if (i < orderedCategories.length - 1) {
        items.add(const SizedBox(height: 16));
      }
    }

    // Add End Game Category at the end if assigned
    if (_categoryProgress.containsKey('End Game')) {
      items.add(const SizedBox(height: 16));
      items.add(
        _buildCategoryListItem(
          category: 'End Game',
          subcategory: null,
          icon: Icons.games_rounded,
          color: const Color(0xFF8B5CF6), // Purple
          progress: _categoryProgress['End Game']?['progress'] ?? 0.0,
          isLocked: false, // Always unlocked as per previous logic
          isCurrent: false,
          customOnTap: () async {
             // Show the introductory dialog first
             await showDialog(
               context: context,
               barrierDismissible: false,
               builder: (BuildContext dialogContext) {
                 return Dialog(
                   backgroundColor: Colors.transparent,
                   child: Container(
                     constraints: const BoxConstraints(maxWidth: 400),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(24),
                       border: Border.all(
                         color: const Color(0xFFF4EF8B),
                         width: 4,
                       ),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.3),
                           blurRadius: 20,
                           offset: const Offset(0, 10),
                         ),
                       ],
                     ),
                     child: Padding(
                       padding: const EdgeInsets.all(24),
                       child: SingleChildScrollView(
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             // Title
                             const Text(
                               'What We\'ve Created Together',
                               style: TextStyle(
                                 fontSize: 24,
                                 fontWeight: FontWeight.w900,
                                 color: Colors.black,
                                 letterSpacing: 0.5,
                               ),
                               textAlign: TextAlign.center,
                             ),
                             const SizedBox(height: 20),
                             
                             // Message
                             const Text(
                               'You\'ve laughed, played, posed, sung, and celebrated\n'
                               'not just an occasion, but a person.\n\n'
                               'Every moment tonight\n'
                               'from the flowers in full bloom to the music, memories, and madness\n'
                               'was a reflection of Deeksha and the people who love her.\n\n'
                               'As we head into the final game,\n'
                               'this is your last chance to go all in\n'
                               'one room, one energy, one unforgettable finish.\n\n'
                               'Let\'s end it the way we started.\n'
                               'Together. 💫',
                               style: TextStyle(
                                 fontSize: 15,
                                 height: 1.6,
                                 color: Colors.black87,
                                 fontWeight: FontWeight.w500,
                               ),
                               textAlign: TextAlign.center,
                             ),
                             const SizedBox(height: 30),
                             
                             // Button
                             SizedBox(
                               width: double.infinity,
                               child: ElevatedButton(
                                 onPressed: () {
                                   Navigator.of(dialogContext).pop();
                                   Navigator.push(
                                     context,
                                     MaterialPageRoute(
                                       builder: (context) => const EndGameScreen(),
                                     ),
                                   );
                                 },
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: const Color(0xFFF4EF8B),
                                   foregroundColor: Colors.black,
                                   padding: const EdgeInsets.symmetric(vertical: 16),
                                   shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(16),
                                   ),
                                   elevation: 0,
                                 ),
                                 child: const Text(
                                   'LET\'S DO THIS',
                                   style: TextStyle(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w900,
                                     letterSpacing: 1,
                                   ),
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                   ),
                 );
               },
             );
          },
        ),
      );
    }
    
    return items;
  }


  /// Build display name for a department (matching admin logic)
  String _buildUserDeptDisplayName(Map<String, dynamic>? dept) {
    if (dept == null) return 'Unknown';
    final title = dept['title'] as String? ?? 'Unknown';
    final category = dept['category'] as String?;
    if (title == 'General' && category != null && category.isNotEmpty) {
      return 'General ($category)';
    }
    return title;
  }

  // Build level-grouped category cards for assigned departments
  // If currentLevelOnly is true, only show the current active level (for Home tab)
  List<Widget> _buildDynamicCategoryCards({bool currentLevelOnly = false}) {
    final List<Widget> cards = [];
    if (_userDeptRecords.isEmpty) {
      cards.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('No courses assigned yet', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ),
      );
      return cards;
    }

    // Determine max completed level across all records
    int maxCompletedLevel = 0;
    for (final record in _userDeptRecords) {
      final cl = record['completed_levels'] as int? ?? 0;
      if (cl > maxCompletedLevel) maxCompletedLevel = cl;
    }

    // Find which levels have assignments
    final Set<int> levelsWithAssignments = {};
    for (final record in _userDeptRecords) {
      final level = record['current_level'] as int? ?? 1;
      levelsWithAssignments.add(level);
    }

    // Always show all 4 levels so user knows the full journey
    const int levelsToDisplay = 4;

    // Determine the current active level (first unlocked, not completed)
    final int activeLevel = maxCompletedLevel + 1;

    for (int level = 1; level <= levelsToDisplay; level++) {
      final isLevelCompleted = level <= maxCompletedLevel;
      final isLevelUnlocked = level <= maxCompletedLevel + 1;

      // If Home tab (currentLevelOnly), only show the active level
      if (currentLevelOnly && level != activeLevel) continue;

      // Get assignments at this level
      final levelAssignments = _userDeptRecords.where((r) {
        return (r['current_level'] as int? ?? 1) == level;
      }).toList();

      cards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLevelCompleted
                  ? Colors.green.shade300
                  : isLevelUnlocked
                      ? const Color(0xFFE8D96F)
                      : Colors.grey.shade300,
              width: 1.5,
            ),
            color: !isLevelUnlocked ? Colors.grey.shade50 : Colors.white,
            boxShadow: [
              if (isLevelUnlocked)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            children: [
              // Level Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isLevelCompleted
                      ? Colors.green.shade50
                      : isLevelUnlocked
                          ? const Color(0xFFFFF9E6)
                          : Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLevelCompleted
                          ? Icons.check_circle_rounded
                          : isLevelUnlocked
                              ? Icons.play_circle_outline_rounded
                              : Icons.lock_rounded,
                      color: isLevelCompleted
                          ? Colors.green
                          : isLevelUnlocked
                              ? const Color(0xFF1E293B)
                              : Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Level $level',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isLevelUnlocked ? const Color(0xFF1E293B) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLevelCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (!isLevelUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'LOCKED',
                          style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              // Assignments under this level
              if (!isLevelUnlocked && levelAssignments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Complete Level ${level - 1} to unlock',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                )
              else if (levelAssignments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'No courses at this level',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...levelAssignments.map((assignment) {
                  final dept = assignment['departments'];
                  final deptName = _buildUserDeptDisplayName(dept);
                  final category = dept?['category'] as String? ?? deptName;
                  final totalQ = assignment['total_questions'] as int? ?? 0;
                  final answeredQ = assignment['answered_questions'] as int? ?? 0;
                  final correctQ = assignment['correct_answers'] as int? ?? 0;
                  final totalScore = assignment['total_score'] as int? ?? 0;
                  final maxScore = assignment['max_possible_score'] as int? ?? (totalQ * 10);
                  final progressVal = totalQ > 0 ? answeredQ / totalQ : 0.0;
                  final isCompleted = progressVal >= 1.0;

                  // Can the user tap this course?
                  final bool canTap = isLevelUnlocked && !isLevelCompleted && !isCompleted;
                  final bool canContinue = canTap && answeredQ > 0 && answeredQ < totalQ;

                  // Pass level number so quiz filters to correct questions
                  final assignmentLevel = assignment['current_level'] as int? ?? level;

                  return InkWell(
                    onTap: canTap
                        ? () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(
                                  category: category,
                                  levelNumber: assignmentLevel,
                                ),
                              ),
                            );
                            if (mounted) _loadData();
                          }
                        : isLevelCompleted
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('This level has been marked as complete by admin'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Course name + status
                          Row(
                            children: [
                              Icon(
                                _getCategoryIcon(category),
                                size: 22,
                                color: isLevelCompleted || !isLevelUnlocked
                                    ? Colors.grey
                                    : _getCategoryColor(category),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  deptName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isLevelUnlocked ? const Color(0xFF1E293B) : Colors.grey,
                                  ),
                                ),
                              ),
                              if (isCompleted || isLevelCompleted)
                                const Icon(Icons.check_circle, size: 18, color: Colors.green)
                              else if (canTap)
                                Icon(Icons.chevron_right_rounded, size: 22, color: Colors.grey[400]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressVal,
                              backgroundColor: Colors.grey.shade200,
                              color: isCompleted || isLevelCompleted
                                  ? Colors.green
                                  : const Color(0xFFFBBF24),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Stats row: Attempted, Correct, Score
                          Row(
                            children: [
                              _buildMiniStat(
                                Icons.quiz_outlined,
                                'Attempted',
                                '$answeredQ / $totalQ',
                                const Color(0xFF1E293B),
                              ),
                              const SizedBox(width: 6),
                              _buildMiniStat(
                                Icons.check_circle_outline,
                                'Correct',
                                '$correctQ / $totalQ',
                                correctQ == totalQ && totalQ > 0 ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              _buildMiniStat(
                                Icons.star_outline,
                                'Score',
                                '$totalScore / $maxScore',
                                totalScore >= maxScore && maxScore > 0 ? Colors.green : Colors.deepPurple,
                              ),
                            ],
                          ),
                          // Continue button if partially done
                          if (canContinue) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () async {
                                  // Try level-specific progress key first, then category
                                  final progressKey = '${category}_L$assignmentLevel';
                                  final catProgress = _categoryProgress[progressKey] ?? _categoryProgress[category];
                                  final startIndex = catProgress?['firstUnansweredIndex'] ?? 0;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuizScreen(
                                        category: category,
                                        levelNumber: assignmentLevel,
                                        startQuestionIndex: startIndex,
                                      ),
                                    ),
                                  );
                                  if (mounted) _loadData();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBBF24).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Continue →',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      );
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If not on home tab, go back to home tab instead of exiting
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
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
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(),
              _buildPathwayTab(),
              _buildInfoTab(),
              _buildProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black.withOpacity(0.4),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.layers_rounded),
                label: 'Levels',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_rounded),
                label: 'Info',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // HOME TAB
  // ============================================
  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFF4EF8B),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top row: avatar + name + level badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFE8D96F)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFBBF24).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Text(_userAvatar, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _lastLoginAgo.isNotEmpty
                                    ? 'Welcome back!  ·  $_lastLoginAgo'
                                    : 'Welcome back!',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'L$_userLevel',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Motivational quote
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF4EF8B).withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _quotes[DateTime.now().day % _quotes.length],
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF6B5A00),
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Stats row
                    Builder(
                      builder: (context) {
                        int completedCount = 0;
                        _categoryProgress.forEach((_, value) {
                          if ((value['progress'] ?? 0.0) >= 1.0) completedCount++;
                        });
                        return Row(
                          children: [
                            _buildHomeStatChip(Icons.check_circle_rounded, 'Completed', '$completedCount', const Color(0xFF10B981)),
                            const SizedBox(width: 10),
                            _buildHomeStatChip(Icons.stars_rounded, 'Points', '$_totalPoints', const Color(0xFFF59E0B)),
                            const SizedBox(width: 10),
                            _buildHomeStatChip(Icons.emoji_events_rounded, 'Level', '$_userLevel', const Color(0xFF8B5CF6)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            
              // Assignments Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Assignment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Complete levels in order to progress',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 14),
                  
                  // Show only current active level on Home tab
                  ..._buildDynamicCategoryCards(currentLevelOnly: true),
                  
                  // End Game Category (only shown if assigned)
                  if (_categoryProgress.containsKey('End Game')) ...[
                    const SizedBox(height: 12),
                    _buildCategoryCard(
                      category: 'End Game',
                      icon: Icons.games_rounded,
                      color: const Color(0xFF8B5CF6), // Purple
                      description: 'Final Verification Challenge',
                      progress: _categoryProgress['End Game']?['progress'] ?? 0.0,
                      isLocked: (_categoryProgress['SOP']?['progress'] ?? 0.0) < 1.0,
                      isCurrent: false, 
                      onTap: () async {
                        // Show the introductory dialog first
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 400),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFF4EF8B),
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Title
                                        const Text(
                                          'What We\'ve Created Together',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                            letterSpacing: 0.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        // Message
                                        const Text(
                                          'You\'ve laughed, played, posed, sung, and celebrated\n'
                                          'not just an occasion, but a person.\n\n'
                                          'Every moment tonight\n'
                                          'from the flowers in full bloom to the music, memories, and madness\n'
                                          'was a reflection of Deeksha and the people who love her.\n\n'
                                          'As we head into the final game,\n'
                                          'this is your last chance to go all in\n'
                                          'one room, one energy, one unforgettable finish.\n\n'
                                          'Let\'s end it the way we started.\n'
                                          'Together. 💫',
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 30),
                                        
                                        // Button
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(dialogContext).pop();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const EndGameScreen(),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFF4EF8B),
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 4,
                                            ),
                                            child: const Text(
                                              'END GAME',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      onContinue: null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon, 
    required String label, 
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2), 
          width: 1
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.white, size: 28),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2F4B).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  label.contains('POINTS') ? Icons.stars_rounded : Icons.check_circle_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CATEGORY CARD BUILDER
  // ============================================
  Widget _buildCategoryCard({
    required String category,
    required IconData icon,
    required Color color,
    required String description,
    required double progress,
    required bool isLocked,
    bool isCurrent = false,
    required VoidCallback onTap,
    VoidCallback? onContinue,
    List<Map<String, String>>? subcategories,
  }) {
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocked ? Colors.grey.shade300 : color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isLocked ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.shade200 : color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Category Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4EF8B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                            if (isLocked) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.lock_rounded,
                                size: 18,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow or Lock Icon
                  if (!isLocked)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLocked ? Colors.grey.shade400 : color,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              
              // Continue Button
              if (onContinue != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.play_arrow_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Subcategories (only for Orientation)
              if (subcategories != null && subcategories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Topics',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...subcategories.map((sub) {
                        final status = sub['status'] ?? 'locked';
                        IconData statusIcon;
                        Color statusColor;
                        
                        if (status == 'completed') {
                          statusIcon = Icons.check_circle_rounded;
                          statusColor = const Color(0xFF10B981); // Green
                        } else if (status == 'in_progress') {
                          statusIcon = Icons.play_circle_rounded;
                          statusColor = const Color(0xFFFBBF24); // Yellow
                        } else {
                          statusIcon = Icons.lock_rounded;
                          statusColor = Colors.grey.shade400;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(statusIcon, size: 16, color: statusColor),
                              const SizedBox(width: 8),
                              Text(
                                sub['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: status == 'locked' 
                                      ? Colors.grey.shade500 
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
              
              // Locked Message
              if (isLocked) ...[ 
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    // Determine the correct unlock message based on category
                    String unlockMessage;
                    if (category == 'Process') {
                      unlockMessage = 'Complete Orientation to unlock';
                    } else if (category == 'SOP') {
                      unlockMessage = 'Complete Process to unlock';
                    } else {
                      // For specific departments (Production, Communication, etc.)
                      // Check which General department is incomplete
                      final orientationComplete = (_categoryProgress['Orientation']?['progress'] ?? 0.0) >= 1.0;
                      final processComplete = (_categoryProgress['Process']?['progress'] ?? 0.0) >= 1.0;
                      final sopComplete = (_categoryProgress['SOP']?['progress'] ?? 0.0) >= 1.0;
                      
                      if (!orientationComplete) {
                        unlockMessage = 'Complete Orientation to unlock';
                      } else if (!processComplete) {
                        unlockMessage = 'Complete Process to unlock';
                      } else if (!sopComplete) {
                        unlockMessage = 'Complete SOP to unlock';
                      } else {
                        unlockMessage = 'Complete all General departments to unlock';
                      }
                    }
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              unlockMessage,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // LEVELS TAB — shows ALL levels (Home shows current only)
  // ============================================
  Widget _buildPathwayTab() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _selectedIndex = 0);
          },
        ),
        title: const Text('All Levels'),
        backgroundColor: const Color(0xFFF4EF8B),
        foregroundColor: Colors.black,
      ),
      body: Container(
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
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'All Levels',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2F4B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View progress across all your levels',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              // Reuse the same level-grouped cards as Home
              ..._buildDynamicCategoryCards(),
              // End Game
              if (_categoryProgress.containsKey('End Game')) ...[
                const SizedBox(height: 12),
                _buildCategoryCard(
                  category: 'End Game',
                  icon: Icons.games_rounded,
                  color: const Color(0xFF8B5CF6),
                  description: 'Final Verification Challenge',
                  progress: _categoryProgress['End Game']?['progress'] ?? 0.0,
                  isLocked: false,
                  isCurrent: false,
                  onTap: () {
                    // Navigate to End Game from Levels tab
                    setState(() => _selectedIndex = 0);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryListItem({
    required String category,
    String? subcategory,
    required IconData icon,
    required Color color,
    required double progress,
    required bool isLocked,
    required bool isCurrent,
    VoidCallback? customOnTap,
  }) {
    return Card(
      elevation: isCurrent ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent 
            ? const BorderSide(color: Color(0xFFF4EF8B), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isLocked ? null : () async {
          if (customOnTap != null) {
            customOnTap();
            return;
          }

          // Check if category is already completed
          if (progress >= 1.0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You have already completed the $category category!'),
                backgroundColor: Colors.green,
              ),
            );
            return;
          }

          // Navigate to quiz for this category
          // Navigate to quiz for this category
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                category: category,
                subcategory: subcategory,
              ),
            ),
          );
          // Refresh data after quiz completion
          if (mounted) setState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.shade200 : const Color(0xFFF4EF8B).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isLocked ? Colors.grey.shade400 : Colors.black,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Category Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                subcategory != null ? '$category - $subcategory' : category,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isLocked ? Colors.grey.shade600 : const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4EF8B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                            if (isLocked) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.lock_rounded,
                                size: 18,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLocked 
                              ? 'Complete previous category to unlock'
                              : 'Tap to continue learning',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLocked)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLocked ? Colors.grey.shade400 : const Color(0xFFF4EF8B),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey.shade600 : color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // INFO TAB
  // ============================================
  Widget _buildInfoTab() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _selectedIndex = 0);
          },
        ),
        title: const Text('Game Guide'),
        backgroundColor: const Color(0xFFF4EF8B),
        foregroundColor: Colors.black,
      ),
      body: Container(
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
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text(
            'Game Guide',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A2F4B)),
          ),
          const SizedBox(height: 4),
          Text(
            'Everything you need to know',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          // What Is This Game?
          _buildExpandableSection(
            icon: Icons.help_outline,
            iconColor: const Color(0xFFE91E63),
            title: 'What Is This Game?',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBoldText('This is a decision-based event simulation game.'),
                const SizedBox(height: 8),
                _buildNormalText('You don\'t just answer questions, you plan, move, choose, fix, and adapt like a real event professional.'),
                const SizedBox(height: 12),
                _buildBoldText('There are no perfect answers, only better decisions.'),
              ],
            ),
          ),
          
          // How the Game Works
          _buildExpandableSection(
            icon: Icons.settings,
            iconColor: const Color(0xFF9C27B0),
            title: 'How the Game Works',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('Each level is a real event scenario'),
                _buildBulletPoint('You unlock information by playing mini-games'),
                _buildBulletPoint('Every choice affects:'),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubBullet('Budget'),
                      _buildSubBullet('Safety'),
                      _buildSubBullet('Guest experience'),
                      _buildSubBullet('Team efficiency'),
                    ],
                  ),
                ),
                _buildBulletPoint('The final level is live event execution'),
              ],
            ),
          ),
          
          // What You'll Be Doing
          _buildExpandableSection(
            icon: Icons.videogame_asset,
            iconColor: const Color(0xFF2196F3),
            title: 'What You\'ll Be Doing',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('Choosing between options'),
                _buildBulletPoint('Moving elements on a live venue map'),
                _buildBulletPoint('Fixing last-minute problems'),
                _buildBulletPoint('Adapting when plans change'),
                _buildBulletPoint('Thinking like a Project Head, not a checklist follower'),
              ],
            ),
          ),
          
          // How You're Scored
          _buildExpandableSection(
            icon: Icons.star,
            iconColor: const Color(0xFFFFC107),
            title: 'How You\'re Scored',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNormalText('You earn points based on:'),
                const SizedBox(height: 8),
                _buildBulletPoint('Smart planning (not overspending)'),
                _buildBulletPoint('Safety-first decisions'),
                _buildBulletPoint('Guest flow & experience'),
                _buildBulletPoint('Crisis handling'),
                _buildBulletPoint('Time efficiency'),
                const SizedBox(height: 12),
                _buildItalicText('Mistakes won\'t end the game.'),
                _buildItalicText('They\'ll just make your job harder... like real life 😉'),
              ],
            ),
          ),
          
          // Types of Challenges
          _buildExpandableSection(
            icon: Icons.extension,
            iconColor: const Color(0xFF4CAF50),
            title: 'Types of Challenges You\'ll See',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('Choose This or That'),
                _buildBulletPoint('Drag & Place Objects'),
                _buildBulletPoint('Fix What Went Wrong'),
                _buildBulletPoint('Re-prioritise Under Pressure'),
                const SizedBox(height: 12),
                _buildEmojiText('✍️ No typing.'),
                _buildEmojiText('📦 No theory dumps.'),
                _buildEmojiText('🧠 Just thinking on your feet.'),
              ],
            ),
          ),
          
          // End Goal
          _buildExpandableSection(
            icon: Icons.flag,
            iconColor: const Color(0xFFFF5722),
            title: 'End Goal',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNormalText('Successfully execute the event with:'),
                const SizedBox(height: 8),
                _buildBulletPoint('Minimal chaos'),
                _buildBulletPoint('Happy client'),
                _buildBulletPoint('Safe guests'),
                _buildBulletPoint('A team that doesn\'t hate you'),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String description}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF6B5CE7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          children: [content],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2F4B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildBoldText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A2F4B),
      ),
    );
  }

  Widget _buildNormalText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[700],
        height: 1.5,
      ),
    );
  }

  Widget _buildItalicText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildEmojiText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A2F4B),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('○ ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PROFILE TAB
  // ============================================
  Widget _buildProfileTab() {
    // Compute quick stats for profile card
    int completedCount = 0;
    _categoryProgress.forEach((_, value) {
      if ((value['progress'] ?? 0.0) >= 1.0) completedCount++;
    });

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Profile header card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with gradient ring
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFFBBF24)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white,
                        child: Text(_userAvatar, style: const TextStyle(fontSize: 36)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail ?? '',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    // Mini stats row
                    Row(
                      children: [
                        _buildProfileStat('Level', '$_userLevel', const Color(0xFF8B5CF6)),
                        Container(width: 1, height: 32, color: Colors.grey.shade200),
                        _buildProfileStat('Points', '$_totalPoints', const Color(0xFFF59E0B)),
                        Container(width: 1, height: 32, color: Colors.grey.shade200),
                        _buildProfileStat('Completed', '$completedCount', const Color(0xFF10B981)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Menu items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileOption(
                        icon: Icons.history_rounded,
                        title: 'Points History',
                        subtitle: 'View your score breakdown',
                        color: const Color(0xFF8B5CF6),
                        onTap: _showPointsHistory,
                      ),
                      _profileDivider(),
                      _buildProfileOption(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profile',
                        subtitle: 'Update your name and avatar',
                        color: const Color(0xFF3B82F6),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          );
                          if (result == true && mounted) _loadData();
                        },
                      ),
                      _profileDivider(),
                      _buildProfileOption(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'App preferences',
                        color: const Color(0xFF6B7280),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                      _profileDivider(),
                      _buildProfileOption(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'FAQs and contact us',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildProfileOption(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    color: Colors.red,
                    onTap: _logout,
                    isDestructive: true,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileDivider() {
    return Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200, indent: 56, endIndent: 16);
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color color = const Color(0xFF6B5CE7),
    bool isDestructive = false,
  }) {
    final effectiveColor = isDestructive ? Colors.red : color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: effectiveColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  // Show orientation required dialog
  void _showOrientationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must complete orientation
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5CE7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school,
                color: Color(0xFF6B5CE7),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Welcome to ENEPL Quiz!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before you begin your learning journey, please complete the Orientation quiz to familiarize yourself with our company values, policies, and procedures.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '📚 16 Topics • 64 Questions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B5CE7),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // Get orientation pathway first
              final orientationPathway = await _pathwayService.getOrientationPathway();
              
              if (!mounted) return;
              
              // Close dialog
              Navigator.of(context).pop();
              
              // Navigate to orientation if pathway exists
              if (orientationPathway != null && mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DepartmentDetailScreen(
                      pathwayId: orientationPathway.id,
                      pathwayName: orientationPathway.title,
                    ),
                  ),
                );
                
                // Reload data after returning from orientation
                if (mounted) {
                  _loadData();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Start Orientation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Show Points History as full page
  Future<void> _showPointsHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PointsHistoryPage(userId: _userId!, totalPoints: _totalPoints),
      ),
    );
  }
}

class _PointsHistoryPage extends StatefulWidget {
  final String userId;
  final int totalPoints;

  const _PointsHistoryPage({required this.userId, required this.totalPoints});

  @override
  State<_PointsHistoryPage> createState() => _PointsHistoryPageState();
}

class _PointsHistoryPageState extends State<_PointsHistoryPage> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _groupedPoints = {};
  Map<String, int> _categoryTotals = {};
  String? _selectedCategory;

  static const _generalCategories = ['Orientation', 'Process', 'SOP'];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    try {
      // 1. Fetch User Progress
      final progressData = await Supabase.instance.client
          .from('usr_progress')
          .select('question_id, question_text, category, level_number, score_earned, created_at')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);
      
      debugPrint('📊 Points History: Fetched ${progressData.length} progress items.');
      
      // 2. Fetch End Game Assignments (Completed)
      final endGameData = await Supabase.instance.client
          .from('end_game_assignments')
          .select('end_game_id, score, completed_at, end_game_configs(name, level)')
          .eq('user_id', widget.userId)
          .not('completed_at', 'is', null);

      // 3. Fetch Question Descriptions (to replace generic titles)
      final Map<String, String> _questionDescriptions = {};
      try {
        final questionsData = await Supabase.instance.client
            .from('questions')
            .select('id, description');
        
        for (var q in questionsData) {
          if (q['description'] != null) {
            _questionDescriptions[q['id'].toString()] = q['description'].toString();
          }
        }
      } catch (e) {
        debugPrint('Error fetching question descriptions: $e');
      }

      // 4. Process & Group Data
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      final Map<String, int> totals = {};

      // Process Progress Data — group by category + level_number
      final Map<String, Map<String, Map<String, dynamic>>> categoryUniqueItems = {};

      for (var item in progressData) {
        final baseCategory = item['category'] ?? 'General';
        final levelNum = item['level_number'] as int? ?? 1;
        // Group key includes level so "Orientation L1" and "Orientation L2" are separate
        final category = '$baseCategory L$levelNum';

        String displayText = item['question_text'] ?? 'Question';
        final qId = item['question_id'].toString();
        
        // Try to find description from fetched questions map
        if (_questionDescriptions.containsKey(qId)) {
          final desc = _questionDescriptions[qId];
          if (desc != null && desc.toString().trim().length > 5) {
             displayText = desc.toString().trim();
          }
        }

        final int score = item['score_earned'] as int? ?? 0;
        
        final pointItem = {
          'text': displayText,
          'subtext': 'Level $levelNum',
          'points': score,
          'date': item['created_at'],
          'type': 'question',
        };

        // Initialize category map if needed
        categoryUniqueItems.putIfAbsent(category, () => {});
        
        // Check if we already have an entry for this question
        final existingItem = categoryUniqueItems[category]![qId];
        final int existingScore = existingItem == null ? -1 : (existingItem['points'] as int);
        
        // Keep the attempt with the highest score
        if (score > existingScore) {
          categoryUniqueItems[category]![qId] = pointItem;
        }
      }
      
      // Convert unique items to the expected list format and calculate totals
      categoryUniqueItems.forEach((category, itemsMap) {
        final itemsList = itemsMap.values.toList();
        // Sort by date descending
        itemsList.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
        
        grouped[category] = itemsList;
        
        // Calculate total
        totals[category] = itemsList.fold(0, (sum, item) => sum + (item['points'] as int));
      });
      
      debugPrint('✅ Final Grouped Data: $totals');
      grouped.forEach((k, v) => debugPrint('   Category $k: ${v.length} items'));

      // Process End Game Data
      for (var item in endGameData) {
        final category = 'End Game';
        final config = item['end_game_configs'];
        final name = config != null ? config['name'] : 'End Game';
        final level = config != null ? config['level'] : 1;
        
        final pointItem = {
          'text': name,
          'subtext': 'Level $level - Verification Complete',
          'points': item['score'] ?? 0,
          'date': item['completed_at'],
          'type': 'end_game',
        };
        
        grouped.putIfAbsent(category, () => []).add(pointItem);
        totals[category] = (totals[category] ?? 0) + (item['score'] as int);
      }

      if (mounted) {
        setState(() {
          _groupedPoints = grouped;
          _categoryTotals = totals;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Display name: "General (Orientation)" for general cats, base name for others
  String _displayName(String base) {
    if (_generalCategories.contains(base)) return 'General ($base)';
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final title = _selectedCategory != null
        ? _displayName(_extractBase(_selectedCategory!))
        : 'Points History';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectedCategory != null) {
              setState(() => _selectedCategory = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(title),
        backgroundColor: const Color(0xFFF4EF8B),
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF9E6), Color(0xFFF4EF8B), Color(0xFFE8D96F)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-header with points badge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A2F4B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedCategory != null
                              ? '${_groupedPoints[_selectedCategory]?.length ?? 0} questions'
                              : 'Score breakdown by level',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_selectedCategory == null ? widget.totalPoints : (_categoryTotals[_selectedCategory] ?? 0)} pts',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedCategory == null
                      ? _buildCategoriesList(ScrollController())
                      : _buildDetailsList(ScrollController()),
            ),
          ],
        ),
      ),
    );
  }

  /// Extract the level number from a key like "Orientation L1" → 1
  int _extractLevel(String key) {
    final match = RegExp(r'L(\d+)$').firstMatch(key);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  /// Extract the base category from a key like "Orientation L1" → "Orientation"
  String _extractBase(String key) {
    return key.replaceAll(RegExp(r'\s*L\d+$'), '');
  }

  Color _catColor(String base) {
    if (base == 'Orientation') return const Color(0xFFF4EF8B);
    if (base == 'Process') return const Color(0xFF3B82F6);
    if (base == 'SOP') return const Color(0xFF10B981);
    if (base == 'Production') return const Color(0xFFEF4444);
    if (base == 'End Game') return const Color(0xFF8B5CF6);
    return const Color(0xFF6B7280);
  }

  IconData _catIcon(String base) {
    if (base == 'Orientation') return Icons.school_rounded;
    if (base == 'Process') return Icons.settings_rounded;
    if (base == 'SOP') return Icons.description_rounded;
    if (base == 'Production') return Icons.precision_manufacturing_rounded;
    if (base == 'End Game') return Icons.games_rounded;
    return Icons.folder_rounded;
  }

  Widget _buildCategoriesList(ScrollController scrollController) {
    if (_groupedPoints.isEmpty) {
      return _buildEmptyState();
    }

    // Group categories by level number
    final Map<int, List<String>> levelGroups = {};
    for (final key in _groupedPoints.keys) {
      if (key == 'End Game') continue;
      final lvl = _extractLevel(key);
      levelGroups.putIfAbsent(lvl, () => []).add(key);
    }

    // Sort levels ascending
    final sortedLevels = levelGroups.keys.toList()..sort();

    // Sort categories within each level
    const order = ['Orientation', 'Process', 'SOP'];
    for (final lvl in sortedLevels) {
      levelGroups[lvl]!.sort((a, b) {
        final ai = order.indexOf(_extractBase(a));
        final bi = order.indexOf(_extractBase(b));
        if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
        if (ai >= 0) return -1;
        if (bi >= 0) return 1;
        return a.compareTo(b);
      });
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        for (final lvl in sortedLevels) ...[
          // Level header
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Level $lvl', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.5)),
                const SizedBox(width: 10),
                Builder(builder: (_) {
                  final lvlTotal = levelGroups[lvl]!.fold<int>(0, (s, k) => s + (_categoryTotals[k] ?? 0));
                  return Text('+$lvlTotal pts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500]));
                }),
              ],
            ),
          ),
          // Categories in this level
          for (final category in levelGroups[lvl]!) ...[
            _buildCategoryRow(category),
            const SizedBox(height: 8),
          ],
        ],
        // End Game at the bottom
        if (_groupedPoints.containsKey('End Game')) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('End Game', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.5)),
              ],
            ),
          ),
          _buildCategoryRow('End Game'),
        ],
      ],
    );
  }

  Widget _buildCategoryRow(String category) {
    final total = _categoryTotals[category] ?? 0;
    final count = _groupedPoints[category]?.length ?? 0;
    final base = category == 'End Game' ? 'End Game' : _extractBase(category);
    final color = _catColor(base);
    final icon = _catIcon(base);
    final isOrientation = base == 'Orientation';

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isOrientation ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isOrientation ? Colors.black54 : color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName(base), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
                  Text('$count questions', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ),
            Text(
              '+$total',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: total > 0 ? const Color(0xFF10B981) : Colors.grey),
            ),
          ],
        ),
    );
  }

  Widget _buildDetailsList(ScrollController scrollController) {
    // Determine background color/theme based on selected category?
    // Maintaining simple white list for now.
    
    final items = _groupedPoints[_selectedCategory] ?? [];
    
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['text'] ?? 'Question',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF1E293B),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subtext'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '+${item['points']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF10B981), // Green
                                ),
                              ),
                            ],
                          ),
                        );
      },
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No points earned yet',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
