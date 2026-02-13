import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/assign_pathways_tab.dart';
import '../../models/pathway.dart';
import 'user_management_screen.dart';
import 'question_bank_management_screen.dart';
import 'department_management_screen.dart';
import 'end_game_config_screen.dart';

class EnhancedAdminDashboard extends StatefulWidget {
  const EnhancedAdminDashboard({super.key});

  @override
  State<EnhancedAdminDashboard> createState() => _EnhancedAdminDashboardState();
}

class _EnhancedAdminDashboardState extends State<EnhancedAdminDashboard> {
  int _selectedIndex = 0;
  int _totalUsers = 0;
  int _totalDepartments = 0;
  int _totalEnrolled = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pathwaysData = [];
  int _quizTimerSeconds = 30; // Default timer duration

  // Insights data
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _inactiveUsers = [];
  List<Map<String, dynamic>> _levelCompletions = [];
  int _totalQuestionsAnswered = 0;
  
  // Scoring thresholds (as percentages)
  double _fullPointsThreshold = 0.5;  // < 50% time = full points
  double _halfPointsThreshold = 0.75; // < 75% time = half points

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadPathways();
    _loadSettings();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      // Get all user profiles, sorted by most recently updated (proxy for last login)
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('user_id, email, level, updated_at, created_at')
          .eq('role', 'user')
          .order('updated_at', ascending: false);

      final profileList = List<Map<String, dynamic>>.from(profiles as List);

      // Recent Activity: last 5 users by updated_at (most recent first)
      final List<Map<String, dynamic>> recent = [];
      for (final p in profileList.take(5)) {
        final email = p['email']?.toString() ?? 'Unknown';
        final level = p['level'] is int ? p['level'] as int : 1;
        final updatedAt = p['updated_at']?.toString() ?? p['created_at']?.toString();
        String timeAgo = '';
        if (updatedAt != null) {
          final dt = DateTime.tryParse(updatedAt);
          if (dt != null) {
            final diff = DateTime.now().difference(dt);
            if (diff.inMinutes < 60) {
              timeAgo = '${diff.inMinutes}m ago';
            } else if (diff.inHours < 24) {
              timeAgo = '${diff.inHours}h ago';
            } else {
              timeAgo = '${diff.inDays}d ago';
            }
          }
        }
        recent.add({'email': email, 'level': level, 'timeAgo': timeAgo});
      }

      // Total questions answered
      int totalAnswered = 0;
      try {
        final allAnswered = await Supabase.instance.client
            .from('usr_progress')
            .select('id')
            .eq('status', 'answered');
        totalAnswered = (allAnswered as List).length;
      } catch (e) {
        debugPrint('Error loading total answered: $e');
      }

      // Needs Attention: users with assignments but no activity for 3+ days
      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in profileList) {
        final uid = p['user_id'];
        if (uid != null) profileMap[uid.toString()] = p;
      }

      List allUsrDept = [];
      try {
        allUsrDept = await Supabase.instance.client
            .from('usr_dept')
            .select('user_id, last_activity_at, assigned_at');
      } catch (e) {
        debugPrint('Error loading usr_dept: $e');
      }

      // Get latest activity per user from usr_dept
      final Map<String, String?> latestActivity = {};
      for (final ud in allUsrDept) {
        final uid = ud['user_id']?.toString();
        if (uid == null) continue;
        // Use last_activity_at, fall back to assigned_at
        final la = ud['last_activity_at']?.toString() ?? ud['assigned_at']?.toString();
        if (la != null) {
          if (!latestActivity.containsKey(uid) || (latestActivity[uid] != null && la.compareTo(latestActivity[uid]!) > 0)) {
            latestActivity[uid] = la;
          }
        } else if (!latestActivity.containsKey(uid)) {
          latestActivity[uid] = null;
        }
      }

      final List<Map<String, dynamic>> inactive = [];
      for (final entry in latestActivity.entries) {
        final profile = profileMap[entry.key];
        if (profile == null || profile['email'] == null) continue;
        final email = profile['email'].toString();
        final level = profile['level'] is int ? profile['level'] as int : 1;
        if (entry.value == null) {
          inactive.add({'email': email, 'days': -1, 'level': level});
        } else {
          final lastActive = DateTime.tryParse(entry.value!);
          if (lastActive != null) {
            final daysSince = DateTime.now().difference(lastActive).inDays;
            if (daysSince >= 3) {
              inactive.add({'email': email, 'days': daysSince, 'level': level});
            }
          }
        }
      }
      inactive.sort((a, b) => ((b['days'] as int?) ?? 0).compareTo((a['days'] as int?) ?? 0));

      // Level Completions: one row per user, max completed_levels across all depts
      List completedDepts = [];
      try {
        completedDepts = await Supabase.instance.client
            .from('usr_dept')
            .select('user_id, completed_levels')
            .gt('completed_levels', 0)
            .order('completed_levels', ascending: false);
      } catch (e) {
        debugPrint('Error loading level completions: $e');
      }

      // Aggregate: keep max completed_levels per user
      final Map<String, int> userMaxLevel = {};
      for (final d in completedDepts) {
        final uid = d['user_id']?.toString();
        if (uid == null) continue;
        final cl = d['completed_levels'] is int ? d['completed_levels'] as int : 0;
        if (!userMaxLevel.containsKey(uid) || cl > userMaxLevel[uid]!) {
          userMaxLevel[uid] = cl;
        }
      }

      final List<Map<String, dynamic>> completions = [];
      for (final entry in userMaxLevel.entries) {
        final profile = profileMap[entry.key];
        if (profile == null) continue;
        final email = profile['email']?.toString() ?? 'Unknown';
        completions.add({
          'email': email,
          'completedLevels': entry.value,
        });
      }
      completions.sort((a, b) => ((b['completedLevels'] as int?) ?? 0).compareTo((a['completedLevels'] as int?) ?? 0));

      if (mounted) {
        setState(() {
          _recentActivity = recent;
          _inactiveUsers = inactive;
          _levelCompletions = completions;
          _totalQuestionsAnswered = totalAnswered;
        });
      }
    } catch (e) {
      debugPrint('Error loading insights: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select('levels')
          .eq('title', 'SYSTEM_CONFIG')
          .maybeSingle();

      if (response != null && response['levels'] != null && (response['levels'] as List).isNotEmpty) {
        final settings = (response['levels'] as List)[0];
        if (mounted) {
          setState(() {
            _quizTimerSeconds = settings['timer_seconds'] ?? 30;
            _fullPointsThreshold = (settings['full_points_threshold'] ?? 0.5).toDouble();
            _halfPointsThreshold = (settings['half_points_threshold'] ?? 0.75).toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _loadPathways() async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select()
          .order('title');
      
      if (mounted) {
        setState(() {
          _pathwaysData = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error loading pathways: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      // Load users count
      final usersResponse = await Supabase.instance.client
          .from('profiles')
          .select();
      
      // Load departments count
      final deptsResponse = await Supabase.instance.client
          .from('departments')
          .select();
      
      // Load enrolled users count (distinct users in usr_dept)
      final enrolledResponse = await Supabase.instance.client
          .from('usr_dept')
          .select('user_id');

      if (mounted) {
        setState(() {
          _totalUsers = (usersResponse as List).length;
          _totalDepartments = (deptsResponse as List).length;
          // Count unique user IDs
          final uniqueUsers = (enrolledResponse as List)
              .map((e) => e['user_id'])
              .toSet();
          _totalEnrolled = uniqueUsers.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  void _showAssignPathwayDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          child: AssignPathwaysTab(
            pathways: _pathwaysData.map((data) => Pathway.fromJson(data)).toList(),
            onAssignmentComplete: () {
              Navigator.pop(context);
              _loadStats();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: _selectedIndex == 0 ? AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF1A2F4B),
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () {
                _loadStats();
                _loadInsights();
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: Container(
                        width: double.infinity,
                        height: double.infinity,
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
                        child: SafeArea(child: _buildSettingsScreen()),
                      ),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
            ),
          ],
        ) : null,
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFFA726),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alt_route),
              label: 'Department',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz),
              label: 'Bank',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
        child: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return DepartmentManagementScreen(
          onBack: () => setState(() => _selectedIndex = 0),
        );
      case 2:
        return QuestionBankManagementScreen(
          onBack: () => setState(() => _selectedIndex = 0),
        );
      case 3:
        return UserManagementScreen(
          onBack: () => setState(() => _selectedIndex = 0),
        );
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Users', _totalUsers.toString(), Icons.people, const Color(0xFF8B5CF6)),
                Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.2)),
                _buildStatItem('Depts', _totalDepartments.toString(), Icons.alt_route, const Color(0xFFFBBF24)),
                Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.2)),
                _buildStatItem('Enrolled', _totalEnrolled.toString(), Icons.school, const Color(0xFFF9A8D4)),
                Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.2)),
                _buildStatItem('Answered', _totalQuestionsAnswered.toString(), Icons.check_circle, const Color(0xFF10B981)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recent Logins
          _buildSectionHeader('Recent Logins', Icons.login_rounded),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: _recentActivity.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text('No users yet', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ),
                  )
                : Column(
                    children: _recentActivity.map((user) {
                      final email = user['email']?.toString() ?? '';
                      final shortEmail = email.contains('@') ? email.split('@')[0] : email;
                      final level = user['level'] is int ? user['level'] as int : 1;
                      final timeAgo = user['timeAgo']?.toString() ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.12),
                              child: const Icon(Icons.person, size: 14, color: Color(0xFF8B5CF6)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(shortEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A2F4B))),
                            ),
                            if (timeAgo.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(timeAgo, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A2F4B).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('L$level', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF1A2F4B))),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Level Completions
          if (_levelCompletions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Level Completions', Icons.emoji_events_rounded),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: _levelCompletions.take(5).map((item) {
                  final email = item['email']?.toString() ?? '';
                  final shortEmail = email.contains('@') ? email.split('@')[0] : email;
                  final completed = item['completedLevels'] is int ? item['completedLevels'] as int : 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFFBBF24).withOpacity(0.15),
                          child: const Icon(Icons.emoji_events, size: 14, color: Color(0xFFFBBF24)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(shortEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A2F4B))),
                        ),
                        _buildLevelDots(completed),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Needs Attention: only show if there are inactive users
          if (_inactiveUsers.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Needs Attention', Icons.warning_amber_rounded),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: _inactiveUsers.take(5).map((user) {
                  final email = user['email']?.toString() ?? '';
                  final shortEmail = email.contains('@') ? email.split('@')[0] : email;
                  final days = user['days'] is int ? user['days'] as int : 0;
                  final level = user['level'] is int ? user['level'] as int : 1;
                  final daysText = days < 0 ? 'Never started' : 'Inactive $days days';
                  final urgency = days < 0 || days >= 7 ? Colors.red : Colors.orange;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: urgency.withOpacity(0.12),
                          child: Icon(Icons.schedule, size: 14, color: urgency),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shortEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A2F4B))),
                              Text(daysText, style: TextStyle(fontSize: 10, color: urgency, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2F4B).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('L$level', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF1A2F4B))),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLevelDots(int completed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 4; i++)
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: i <= completed ? const Color(0xFF10B981) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '$i',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: i <= completed ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1A2F4B)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2F4B)),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A2F4B)),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDepartmentTab() {
    return const Center(
      child: Text(
        'Department Management - Coming Soon',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.canPop(context) ? Navigator.pop(context) : setState(() => _selectedIndex = 0),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF1A2F4B)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Settings',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A2F4B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Question Timer Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.timer, color: Color(0xFFFBBF24), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Question Timer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2F4B))),
                          Text('Time limit per question', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _quizTimerSeconds == 0 ? 'Off' : '${_quizTimerSeconds}s',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2F4B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Slider(
                  value: _quizTimerSeconds.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  activeColor: const Color(0xFFFBBF24),
                  inactiveColor: Colors.grey[300],
                  label: _quizTimerSeconds == 0 ? 'Off' : '$_quizTimerSeconds s',
                  onChanged: (value) => setState(() => _quizTimerSeconds = value.toInt()),
                ),
                
                // Preset buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPresetButton('15s', 15),
                    _buildPresetButton('30s', 30),
                    _buildPresetButton('45s', 45),
                    _buildPresetButton('60s', 60),
                    _buildPresetButton('90s', 90),
                    _buildPresetButton('Off', 0),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        setState(() => _isLoading = true);
                        
                        final settings = {
                          'timer_seconds': _quizTimerSeconds,
                          'full_points_threshold': _fullPointsThreshold,
                          'half_points_threshold': _halfPointsThreshold,
                          'updated_at': DateTime.now().toIso8601String(),
                        };

                        final existing = await Supabase.instance.client
                            .from('departments')
                            .select('id')
                            .eq('title', 'SYSTEM_CONFIG')
                            .limit(1)
                            .maybeSingle();

                        if (existing != null) {
                          await Supabase.instance.client
                              .from('departments')
                              .update({'levels': [settings], 'description': 'System Configuration - Do not delete'})
                              .eq('id', existing['id']);
                        } else {
                          await Supabase.instance.client
                              .from('departments')
                              .insert({
                                'title': 'SYSTEM_CONFIG',
                                'description': 'System Configuration - Do not delete',
                                'levels': [settings],
                                'category': 'SYSTEM',
                                'subcategory': 'CONFIG',
                              });
                        }

                        if (mounted) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_quizTimerSeconds == 0 ? 'Question timer disabled' : 'Timer set to $_quizTimerSeconds seconds'),
                              backgroundColor: const Color(0xFF3B82F6),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error saving settings: $e');
                        if (mounted) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2F4B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Timer Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // End Game Configuration Link
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EndGameConfigScreen(onBack: () => Navigator.pop(context)),
                ),
              ),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7043).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.videogame_asset_rounded, color: Color(0xFFFF7043), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('End Game Configuration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2F4B))),
                          Text('Manage end game levels and items', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPresetButton(String label, int seconds) {
    final isSelected = _quizTimerSeconds == seconds;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _quizTimerSeconds = seconds;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF8B5CF6),
        side: BorderSide(
          color: const Color(0xFF8B5CF6),
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
}
