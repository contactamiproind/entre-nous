import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/assign_pathways_tab.dart';
import '../../models/pathway.dart';
import 'user_management_screen.dart';
import 'question_bank_management_screen.dart';
import 'department_management_screen.dart';

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
  
  // Scoring thresholds (as percentages)
  double _fullPointsThreshold = 0.5;  // < 50% time = full points
  double _halfPointsThreshold = 0.75; // < 75% time = half points

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadPathways();
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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStats,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF8B5CF6),
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
              label: 'Q-Bank',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
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
            Color(0xFF6EC1E4),
            Color(0xFF9BA8E8),
            Color(0xFFE8A8D8),
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
      case 4:
        return _buildSettingsScreen();
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
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          
          // New Stats Design (Single container with Row)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Users
                _buildStatItem(
                  'Users',
                  _totalUsers.toString(),
                  Icons.people,
                  const Color(0xFF8B5CF6),
                ),
                
                // Divider
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.3),
                ),
                
                // Departments
                _buildStatItem(
                  'Depts',
                  _totalDepartments.toString(),
                  Icons.alt_route,
                  const Color(0xFFFBBF24),
                ),
                
                 // Divider
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.3),
                ),
                
                // Enrolled
                _buildStatItem(
                  'Enrolled',
                  _totalEnrolled.toString(),
                  Icons.school,
                  const Color(0xFFF9A8D4),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          // Quick Action Buttons - Vertical Stack
          Column(
            children: [
              _buildActionButton(
                'User Profile',
                Icons.person_search_rounded,
                const Color(0xFF42A5F5),
                () => setState(() => _selectedIndex = 3), // Navigate to Users tab
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'Departments',
                Icons.alt_route_rounded,
                const Color(0xFF8B5CF6),
                () => setState(() => _selectedIndex = 1), // Navigate to Department tab
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'Manage Question Bank',
                Icons.quiz_rounded,
                const Color(0xFFFBBF24),
                () => setState(() => _selectedIndex = 2), // Navigate to Q-Bank tab
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2F4B),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Timer Configuration Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.timer,
                        color: Color(0xFF8B5CF6),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quiz Timer',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2F4B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Set time limit for each question',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Timer Duration Slider
                Row(
                  children: [
                    const Text(
                      'Duration:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2F4B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _quizTimerSeconds == 0 ? 'Disabled' : '$_quizTimerSeconds seconds',
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
                
                Slider(
                  value: _quizTimerSeconds.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  activeColor: const Color(0xFF8B5CF6),
                  inactiveColor: Colors.grey[300],
                  label: _quizTimerSeconds == 0 ? 'Disabled' : '$_quizTimerSeconds s',
                  onChanged: (value) {
                    setState(() {
                      _quizTimerSeconds = value.toInt();
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Quick preset buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetButton('15s', 15),
                    _buildPresetButton('30s', 30),
                    _buildPresetButton('45s', 45),
                    _buildPresetButton('60s', 60),
                    _buildPresetButton('90s', 90),
                    _buildPresetButton('Disable', 0),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Scoring Thresholds Section
                const Divider(thickness: 2),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Color(0xFFFBBF24),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scoring Thresholds',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2F4B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Configure time-based point breakpoints',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Full Points Threshold
                Row(
                  children: [
                    const Text(
                      'Full Points (100):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2F4B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '< ${(_fullPointsThreshold * 100).toInt()}% time',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _fullPointsThreshold,
                  min: 0.2,
                  max: 0.8,
                  divisions: 12,
                  activeColor: Colors.green,
                  label: '${(_fullPointsThreshold * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() {
                      _fullPointsThreshold = value;
                      // Ensure half points threshold is always higher
                      if (_halfPointsThreshold <= _fullPointsThreshold) {
                        _halfPointsThreshold = (_fullPointsThreshold + 0.1).clamp(0.3, 0.9);
                      }
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Half Points Threshold
                Row(
                  children: [
                    const Text(
                      'Half Points (50):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2F4B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '< ${(_halfPointsThreshold * 100).toInt()}% time',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _halfPointsThreshold,
                  min: 0.3,
                  max: 0.9,
                  divisions: 12,
                  activeColor: Colors.orange,
                  label: '${(_halfPointsThreshold * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() {
                      _halfPointsThreshold = value;
                      // Ensure full points threshold is always lower
                      if (_fullPointsThreshold >= _halfPointsThreshold) {
                        _fullPointsThreshold = (_halfPointsThreshold - 0.1).clamp(0.2, 0.8);
                      }
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Quarter Points Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Quarter Points (25): ≥ ${(_halfPointsThreshold * 100).toInt()}% time',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final fullPct = (_fullPointsThreshold * 100).toInt();
                      final halfPct = (_halfPointsThreshold * 100).toInt();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _quizTimerSeconds == 0
                                ? 'Quiz timer disabled'
                                : 'Settings saved!\nTimer: $_quizTimerSeconds sec\nFull pts: <$fullPct%, Half pts: <$halfPct%',
                          ),
                          backgroundColor: const Color(0xFF8B5CF6),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
