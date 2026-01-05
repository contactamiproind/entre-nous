import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pathway_detail_screen.dart';

class MyDepartmentsScreen extends StatefulWidget {
  const MyDepartmentsScreen({super.key});

  @override
  State<MyDepartmentsScreen> createState() => _MyDepartmentsScreenState();
}

class _MyDepartmentsScreenState extends State<MyDepartmentsScreen> {
  List<Map<String, dynamic>> _enrolledDepartments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load only enrolled departments (assigned by admin)
      final enrolled = await Supabase.instance.client
          .from('usr_dept')
          .select('id, user_id, dept_id, dept_name, is_current, total_questions, answered_questions, status, assigned_at, departments(id, title, description)')
          .eq('user_id', user.id)
          .order('assigned_at');

      setState(() {
        _enrolledDepartments = List<Map<String, dynamic>>.from(enrolled);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _switchToDepartment(String pathwayId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Update is_current for all pathways
      await Supabase.instance.client
          .from('usr_dept')
          .update({'is_current': false})
          .eq('user_id', user.id);

      await Supabase.instance.client
          .from('usr_dept')
          .update({'is_current': true})
          .eq('user_id', user.id)
          .eq('dept_id', pathwayId);

      _loadDepartments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getDepartmentColor(String name) {
    switch (name.toLowerCase()) {
      case 'communication':
        return Colors.blue;
      case 'creative':
        return Colors.purple;
      case 'ideation':
        return Colors.orange;
      case 'production':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Departments'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enrolled Departments
                      const Text(
                        'My Enrolled Departments',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_enrolledDepartments.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text('No departments enrolled yet'),
                            ),
                          ),
                        )
                      else
                        ..._enrolledDepartments.map((enrollment) {
                          // Use dept_name from usr_dept (already saved correctly)
                          final deptId = enrollment['dept_id'];
                          final deptName = enrollment['dept_name'] ?? 'Unknown Department';
                          final pathway = enrollment['departments'];
                          
                          // Use dept_name from usr_dept as primary source
                          final deptTitle = deptName;
                          final deptDescription = pathway?['description'] ?? 'Tap to view levels and questions';
                          
                          final isCurrent = enrollment['is_current'] == true;
                          final color = _getDepartmentColor(deptTitle);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isCurrent ? 8 : 2,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DepartmentDetailScreen(
                                      pathwayId: deptId,
                                      pathwayName: deptTitle,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: isCurrent
                                      ? Border.all(color: color, width: 3)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.school,
                                          color: color,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              deptTitle,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              deptDescription,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            if (isCurrent)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: color,
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
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!isCurrent)
                                        TextButton(
                                          onPressed: () => _switchToDepartment(deptId),
                                          child: const Text('Switch'),
                                        ),
                                      const Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 32),

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
                                'New pathways are assigned by your administrator. Contact them to request additional learning paths.',
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
                ),
    );
  }
}
