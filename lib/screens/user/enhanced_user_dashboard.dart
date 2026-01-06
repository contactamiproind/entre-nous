import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/pathway.dart';
import '../../models/user_assignment.dart';
import '../../services/pathway_service.dart';
import '../../services/assignment_service.dart';
import '../../services/progress_service.dart';
import 'profile_actions_screen.dart';
import 'pathway_detail_screen.dart';

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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDF8F0), // Cream
              Color(0xFFFFF5E6), // Lighter cream
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
              color: const Color(0xFF1A2F4B).withOpacity(0.08),
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
          selectedItemColor: const Color(0xFF1A2F4B), // Navy
          unselectedItemColor: const Color(0xFF1A2F4B).withOpacity(0.4),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Department',
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
    );
  }

  // ============================================
  // HOME TAB
  // ============================================
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF1A2F4B),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header
            Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A2F4B), // Navy
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                  child: Column(
                    children: [
                      // Profile Picture
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8C67D), // Yellow ring
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
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _userAvatar,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User Name
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back, $_userName!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Rank and Level Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBadge(
                            icon: Icons.star_rounded,
                            label: 'RANK',
                            value: '#${_userProgress?['current_level'] ?? 1}',
                            color: const Color(0xFFF08A7E), // Coral
                          ),
                          const SizedBox(width: 16),
                          _buildBadge(
                            icon: Icons.bar_chart_rounded,
                            label: 'LEVEL',
                            value: '${_userProgress?['current_level'] ?? 1}',
                            color: const Color(0xFF6BCB9F), // Teal
                          ),
                        ],
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
            // Current Pathway Card
            if (_currentPathway != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DepartmentDetailScreen(
                          pathwayId: _currentPathway!.id,
                          pathwayName: _currentPathway!.title,
                        ),
                      ),
                    );
                    // Handle tab switching or data refresh
                    if (result is int && mounted) {
                      setState(() => _selectedIndex = result);
                    } else if (result == true && mounted) {
                      _loadData();
                    }
                  },
                  child: Container(
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
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6BCB9F).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.map_rounded, color: Color(0xFF6BCB9F), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'CURRENT DEPARTMENT',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[400],
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: Color(0xFF1A2F4B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentPathway!.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A2F4B),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (_userProgress?['current_level'] ?? 1) / 
                                           (_currentLevels.isNotEmpty ? _currentLevels.length : 1),
                                    backgroundColor: const Color(0xFF1A2F4B).withOpacity(0.05),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6BCB9F), // Teal
                                    ),
                                    minHeight: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Lvl ${_userProgress?['current_level'] ?? 1} / ${_currentLevels.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A2F4B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
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
  // PATHWAY TAB
  // ============================================
  Widget _buildPathwayTab() {
    if (_assignments.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() => _selectedIndex = 0); // Navigate to Home tab
            },
          ),
          title: const Text('Department'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.route_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Pathway Assigned',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact your admin to get assigned to a pathway',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          const Text(
            'My Enrolled Departments',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2F4B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any department to view levels and start quizzes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Pathways List
          ..._assignments.map((assignment) {
            // Find the pathway for this assignment
            final pathway = _pathways.firstWhere(
              (p) => p.id == assignment.pathwayId,
              orElse: () => Pathway(
                id: assignment.pathwayId,
                title: 'Unknown Pathway',
                description: null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            
            final isCurrent = _currentPathway?.id == pathway.id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: isCurrent ? 4 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isCurrent 
                    ? const BorderSide(color: Color(0xFF6BCB9F), width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DepartmentDetailScreen(
                        pathwayId: pathway.id,
                        pathwayName: pathway.title,
                      ),
                    ),
                  );
                  if (result is int && mounted) {
                    // User tapped a different tab in pathway detail screen
                    setState(() => _selectedIndex = result);
                  } else if (result == true && mounted) {
                    _loadData();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B5CE7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF6B5CE7),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Pathway Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pathway.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2F4B),
                              ),
                            ),
                            if (pathway.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                pathway.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (isCurrent) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6BCB9F),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF1A2F4B),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 16),
          
          // Info message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New departments are assigned by your administrator. Contact them to request additional learning paths.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            setState(() => _selectedIndex = 0); // Navigate to Home tab
          },
        ),
        title: const Text('Information'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(
            icon: Icons.school,
            title: 'About ENEPL Quiz',
            description: 'Learn, Practice, and Excel with our comprehensive quiz platform.',
          ),
          _buildInfoCard(
            icon: Icons.help_outline,
            title: 'How to Use',
            description: 'Complete quizzes in your assigned pathway to progress through levels.',
          ),
          _buildInfoCard(
            icon: Icons.emoji_events,
            title: 'Achievements',
            description: 'Earn ranks and badges by completing quizzes and improving your scores.',
          ),
        ],
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
              child: Icon(icon, color: const Color(0xFF6B5CE7)),
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

  // ============================================
  // PROFILE TAB
  // ============================================
  Widget _buildProfileTab() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _selectedIndex = 0); // Navigate to Home tab
          },
        ),
        title: const Text('Profile'),
      ),
      body: ListView(
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
