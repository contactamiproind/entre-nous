import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_question_screen.dart';
import '../widgets/assign_pathways_tab.dart';
import '../models/pathway.dart';
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
      
      // Load enrolled users count (distinct users in user_pathway)
      final enrolledResponse = await Supabase.instance.client
          .from('user_pathway')
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2F4B),
        elevation: 0,
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
        selectedItemColor: const Color(0xFF1A2F4B),
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
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const DepartmentManagementScreen();
      case 2:
        return const QuestionBankManagementScreen();
      case 3:
        return const UserManagementScreen();
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
              color: Color(0xFF1A2F4B),
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
                  const Color(0xFF42A5F5),
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
                  const Color(0xFF66BB6A),
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
                  const Color(0xFFFF9800),
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
              color: Color(0xFF1A2F4B),
            ),
          ),
          const SizedBox(height: 12),
          // Quick Action Buttons - New Design
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                'User Profile',
                Icons.person_search_rounded,
                const Color(0xFF42A5F5),
                () => setState(() => _selectedIndex = 3), // Navigate to Users tab
              ),
              _buildActionButton(
                'Manage Department',
                Icons.alt_route_rounded,
                const Color(0xFF8B5CF6),
                () => setState(() => _selectedIndex = 1), // Navigate to Department tab
              ),
              _buildActionButton(
                'Manage Question Bank',
                Icons.quiz_rounded,
                const Color(0xFF10B981),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
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
}
