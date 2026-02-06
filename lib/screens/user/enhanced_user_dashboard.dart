import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/stable_random.dart';
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

class _EnhancedUserDashboardState extends State<EnhancedUserDashboard> {
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
  int _selectedIndex = 0;
  
  // Category progress tracking for Continue feature
  Map<String, Map<String, dynamic>> _categoryProgress = {}; // category -> {total, answered, firstUnansweredIndex}

  @override
  void initState() {
    super.initState();
    _loadData();
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
        } else {
          _userName = user.email?.split('@')[0] ?? 'Explorer';
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
        _userName = user.email?.split('@')[0] ?? 'Explorer';
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
        ]);

        progress = results[0] as Map<String, dynamic>?;
        assignments = results[1] as List<UserAssignment>;
        pathways = results[2] as List<Pathway>;
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
      // Get all departments assigned to this user from usr_dept
      final userDeptsData = await Supabase.instance.client
          .from('usr_dept')
          .select('dept_id, departments(id, title, category)')
          .eq('user_id', _userId!);
      
      debugPrint('📊 Found ${userDeptsData.length} assigned departments for user');
      
      // Extract unique categories from assigned departments
      final assignedCategories = <String>{};
      for (final userDept in userDeptsData) {
        final dept = userDept['departments'];
        if (dept != null && dept['category'] != null) {
          assignedCategories.add(dept['category']);
        }
      }
      
      debugPrint('📋 Assigned categories: $assignedCategories');
      
      for (final category in assignedCategories) {
        final deptData = await Supabase.instance.client.from('departments').select('id').eq('category', category).maybeSingle();
        if (deptData == null) continue;
        final deptId = deptData['id'];
        final usrDeptData = await Supabase.instance.client.from('usr_dept').select('id').eq('user_id', _userId!).eq('dept_id', deptId).maybeSingle();
        if (usrDeptData == null) {
          _categoryProgress[category] = {'total': 0, 'answered': 0, 'firstUnansweredIndex': 0, 'progress': 0.0};
          continue;
        }
        final usrDeptId = usrDeptData['id'];
        final questionsDataRaw = await Supabase.instance.client.from('questions').select('id').eq('dept_id', deptId).order('created_at').order('id', ascending: true); // Deterministic order
        
        // --- DUPLICATE SHUFFLE LOGIC FROM QUIZ_SCREEN ---
        // This is critical to ensure the index matches what the user sees in the quiz
        // Using StableRandom to ensure consistency across Web and Mobile
        
        final String seedString = '${_userId}_${deptId}';
        final int seed = StableRandom.getStableHash(seedString);
        
        final stableRandom = StableRandom(seed);
        final List<dynamic> questionsData = List.from(questionsDataRaw);
        stableRandom.shuffle(questionsData);
        // ------------------------------------------------
        
        // --- DYNAMIC REORDERING (MATCHING QUIZ SCREEN) ---
        // We must apply the exact same "Answered First" logic here
        // The progressData fetch above needs to be used for this sort
        
        final progressData = await Supabase.instance.client.from('usr_progress').select('question_id, status').eq('usr_dept_id', usrDeptId).order('created_at');
        
        final Set<String> answeredQuestionIds = progressData
            .where((p) => p['status'] == 'answered')
            .map((p) => p['question_id'].toString())
            .toSet();

        final List<dynamic> answeredQuestions = [];
        final List<dynamic> unansweredQuestions = [];

        for (var q in questionsData) {
          if (answeredQuestionIds.contains(q['id'].toString())) {
            answeredQuestions.add(q);
          } else {
            unansweredQuestions.add(q);
          }
        }
        
        // Re-construct the list in-place to match Quiz Screen order
        questionsData.clear();
        questionsData.addAll(answeredQuestions);
        questionsData.addAll(unansweredQuestions);
        // ------------------------------------------------
        
        final totalQuestions = questionsData.length;
        // Re-fetch or reuse progress data is fine, logic below iterates the *sorted* list
        
        int answeredCount = 0;
        int firstUnansweredIndex = 0;
        bool foundUnanswered = false;
        
        // Iterate through REORDERED questions
        for (int i = 0; i < questionsData.length; i++) {
          final questionId = questionsData[i]['id'];
          final progress = progressData.firstWhere((p) => p['question_id'] == questionId, orElse: () => {'status': 'pending'});
          if (progress['status'] == 'answered') {
            answeredCount++;
          } else if (!foundUnanswered) {
            firstUnansweredIndex = i;
            foundUnanswered = true;
          }
        }
        if (!foundUnanswered && totalQuestions > 0) firstUnansweredIndex = 0;
        final progressPercentage = totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;
        _categoryProgress[category] = {'total': totalQuestions, 'answered': answeredCount, 'firstUnansweredIndex': firstUnansweredIndex, 'progress': progressPercentage};
        debugPrint('📊 $category Progress: $answeredCount/$totalQuestions (${(progressPercentage * 100).toStringAsFixed(0)}%), First unanswered shuffled index: $firstUnansweredIndex');
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading category progress: $e');
    }
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
      return (_categoryProgress['Orientation']?['progress'] ?? 0.0) < 1.0;
    }
    
    if (category == 'SOP') {
      return (_categoryProgress['Process']?['progress'] ?? 0.0) < 1.0;
    }
    
    // Specific departments: must complete all General departments first
    final orientationComplete = (_categoryProgress['Orientation']?['progress'] ?? 0.0) >= 1.0;
    final processComplete = (_categoryProgress['Process']?['progress'] ?? 0.0) >= 1.0;
    final sopComplete = (_categoryProgress['SOP']?['progress'] ?? 0.0) >= 1.0;
    
    if (!orientationComplete || !processComplete || !sopComplete) {
      return true; // Lock all specific departments until General is complete
    }
    
    // TODO: Implement display_order based locking for specific departments
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
      if (!generalOrder.contains(category)) {
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
    
    return items;
  }


  // Build category cards dynamically for all assigned departments
  List<Widget> _buildDynamicCategoryCards() {
    final List<Widget> cards = [];
    
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
      if (!generalOrder.contains(category)) {
        orderedCategories.add(category);
      }
    }
    
    debugPrint('🎨 Building cards for categories: $orderedCategories');
    
    // Build cards for each category
    for (final category in orderedCategories) {
      final progress = _categoryProgress[category];
      if (progress == null) continue;
      
      final isLocked = _isCategoryLocked(category);
      final progressValue = progress['progress'] ?? 0.0;
      final isCurrent = !isLocked && progressValue < 1.0;
      
      cards.add(
        _buildCategoryCard(
          category: category,
          icon: _getCategoryIcon(category),
          color: _getCategoryColor(category),
          description: _getCategoryDescription(category),
          progress: progressValue,
          isLocked: isLocked,
          isCurrent: isCurrent,
          onTap: () async {
            // Prevent retake if completed
            if (progressValue >= 1.0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You have already completed the $category category!'),
                  backgroundColor: Colors.green,
                ),
              );
              return;
            }

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreen(
                  category: category,
                ),
              ),
            );
            if (mounted) _loadData();
          },
          onContinue: progress['progress'] != null && progress['progress'] > 0 && progress['progress'] < 1.0
              ? () async {
                  final startIndex = progress['firstUnansweredIndex'] ?? 0;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        category: category,
                        startQuestionIndex: startIndex,
                      ),
                    ),
                  );
                  if (mounted) _loadData();
                }
              : null,
        ),
      );
      
      cards.add(const SizedBox(height: 12));
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

    return WillPopScope(
      onWillPop: () async {
        // If not on home tab, go back to home tab instead of exiting
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false; // Don't pop the route
        }
        // If on home tab, prevent back navigation (stay on dashboard)
        return false;
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
                icon: Icon(Icons.map_rounded),
                label: 'Categories',
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
              Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF4EF8B), // Yellow
                        Color(0xFFE8D96F), // Darker yellow
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF4EF8B).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24), // Yellow ring
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _userAvatar,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Decorative circles
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            // Stats Grid
                  Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            // Calculate completed categories dynamically
                            int completedCount = 0;
                            _categoryProgress.forEach((_, value) {
                              if ((value['progress'] ?? 0.0) >= 1.0) {
                                completedCount++;
                              }
                            });
                            
                            return _buildStatCard(
                              'QUIZ COMPLETED',
                              '$completedCount',
                              Colors.blue,
                            );
                          }
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIndex = 1; // Switch to Pathway tab
                            });
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: _buildStatCard(
                            'QUIZZES ASSIGNED',
                            '${_assignments.length}',
                            Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Learning Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learning Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete categories in order',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dynamically build category cards for all assigned departments
                  ..._buildDynamicCategoryCards(),
                  
                  // End Game Category (always shown, always unlocked)
                  const SizedBox(height: 12),
                  _buildCategoryCard(
                    category: 'End Game',
                    icon: Icons.games_rounded,
                    color: const Color(0xFF8B5CF6), // Purple
                    description: 'Final Verification Challenge',
                    progress: 0.0,
                    isLocked: false,
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
                          );
                        },
                      );
                    },
                    onContinue: null,
                  ),
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
                  label.contains('ASSIGNED') ? Icons.assignment_rounded : Icons.check_circle_rounded,
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
                  overflow: TextOverflow.ellipsis,
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
  // PATHWAY TAB
  // ============================================
  Widget _buildPathwayTab() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _selectedIndex = 0); // Navigate to Home tab
          },
        ),
        title: const Text('My Categories'),
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
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(20),
          children: [
            // Header
            const Text(
              'Learning Categories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2F4B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete categories in order to unlock the next one',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Dynamically build category list items
            ..._buildDynamicCategoryListItems(),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() => _selectedIndex = 0); // Navigate to Home tab
          },
        ),
        title: const Text('Information', style: TextStyle(color: Colors.black)),
      ),
      extendBodyBehindAppBar: true,
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
          child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2F4B),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
          ],
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() => _selectedIndex = 0); // Navigate to Home tab
          },
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
      ),
      extendBodyBehindAppBar: true,
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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B5CE7).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _userAvatar,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userEmail ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        // Profile Options
        _buildProfileOption(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            );
            // Reload data if profile was updated
            if (result == true && mounted) {
              _loadData();
            }
          },
        ),

        _buildProfileOption(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        _buildProfileOption(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
            );
          },
        ),
        _buildProfileOption(
          icon: Icons.logout,
          title: 'Logout',
          onTap: _logout,
          isDestructive: true,
        ),
        ],
        ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF6B5CE7),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
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
              child: const Icon(
                Icons.school,
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
}
