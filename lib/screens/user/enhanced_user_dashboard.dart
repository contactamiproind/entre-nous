import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/pathway.dart';
import '../../models/user_assignment.dart';
import '../../services/pathway_service.dart';
import '../../services/assignment_service.dart';
import '../../services/progress_service.dart';
import 'profile_actions_screen.dart';
import 'pathway_detail_screen.dart';
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
                Color(0xFF6EC1E4), // Light blue
                Color(0xFF9BA8E8), // Purple-blue
                Color(0xFFE8A8D8), // Pink
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
            selectedItemColor: const Color(0xFF8B5CF6), // Purple
            unselectedItemColor: const Color(0xFF8B5CF6).withOpacity(0.4),
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
        color: const Color(0xFF8B5CF6),
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
                        Color(0xFF8B5CF6), // Purple
                        Color(0xFF6366F1), // Indigo
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
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
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Level Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFBBF24).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bar_chart_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LVL ${_userProgress?['current_level'] ?? 2}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
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
                        child: _buildStatCard(
                          'QUIZ COMPLETED',
                          '${_userProgress?['completed_assignments'] ?? 0}',
                          Colors.blue,
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
            
            // Current Category Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () async {
                  // Navigate to Orientation quiz
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizScreen(
                        category: 'Orientation',
                      ),
                    ),
                  );
                  // Refresh data after quiz completion
                  if (mounted) _loadData();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8B5CF6), // Purple
                        Color(0xFF6366F1), // Indigo
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.play_circle_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENTLY LEARNING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.8),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Orientation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
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
    required VoidCallback onTap,
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
                      color: isLocked ? Colors.grey.shade400 : color,
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
                            Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isLocked ? Colors.grey.shade600 : const Color(0xFF1E293B),
                                letterSpacing: 0.5,
                              ),
                            ),
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
                            color: Colors.grey.shade600,
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
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isLocked ? Colors.grey.shade600 : color,
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
                Container(
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
                          category == 'Process' 
                              ? 'Complete Orientation to unlock'
                              : 'Complete Process to unlock',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
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
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6EC1E4), // Light blue
              Color(0xFF9BA8E8), // Purple-blue
              Color(0xFFE8A8D8), // Pink
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
            
            // Orientation Category
            _buildCategoryListItem(
              category: 'Orientation',
              subcategory: null,
              icon: Icons.school_rounded,
              color: const Color(0xFF8B5CF6),
              progress: 0.45,
              isLocked: false,
              isCurrent: true,
            ),
            const SizedBox(height: 16),
            
            // Process Category
            _buildCategoryListItem(
              category: 'Process',
              subcategory: null,
              icon: Icons.settings_rounded,
              color: const Color(0xFF3B82F6),
              progress: 0.0,
              isLocked: true,
              isCurrent: false,
            ),
            const SizedBox(height: 16),
            
            // SOP Category
            _buildCategoryListItem(
              category: 'SOP',
              subcategory: null,
              icon: Icons.description_rounded,
              color: const Color(0xFF10B981),
              progress: 0.0,
              isLocked: true,
              isCurrent: false,
            ),
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
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isLocked ? null : () async {
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
                      color: isLocked ? Colors.grey.shade200 : color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isLocked ? Colors.grey.shade400 : color,
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
                            Text(
                              subcategory != null ? '$category - $subcategory' : category,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isLocked ? Colors.grey.shade600 : const Color(0xFF1E293B),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                    isLocked ? Colors.grey.shade400 : color,
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() => _selectedIndex = 0); // Navigate to Home tab
          },
        ),
        title: const Text('Information', style: TextStyle(color: Colors.white)),
      ),
      extendBodyBehindAppBar: true,
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() => _selectedIndex = 0); // Navigate to Home tab
          },
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
      ),
      extendBodyBehindAppBar: true,
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
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
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
