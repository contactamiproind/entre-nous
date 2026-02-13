import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'department_questions_screen.dart';

class DepartmentManagementScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const DepartmentManagementScreen({super.key, this.onBack});

  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select()
          .order('title');

      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading departments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddDepartmentDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Department Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter department name')),
                );
                return;
              }

              try {
                await Supabase.instance.client.from('departments').insert({
                  'title': titleController.text,
                  'description': descriptionController.text,
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Department added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadDepartments();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDepartment(String deptId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: const Text('Are you sure you want to delete this department?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('departments')
            .delete()
            .eq('id', deptId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Department deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDepartments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: widget.onBack,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF1A2F4B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Departments',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2F4B),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      width: 32,
                      child: FloatingActionButton(
                        onPressed: _showAddDepartmentDialog,
                        backgroundColor: const Color(0xFF3B82F6),
                        elevation: 2,
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
          // Departments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _departments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('No departments found', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: _showAddDepartmentDialog,
                              child: const Text('Add your first department', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDepartments,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: _departments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final dept = _departments[index];
                            String displayTitle = dept['title'] ?? 'No title';
                            final category = dept['category']?.toString() ?? '';
                            final description = dept['description']?.toString() ?? '';
                            if (displayTitle == 'General' && category.isNotEmpty) {
                              displayTitle = 'General ($category)';
                            }
                            final isSystem = displayTitle == 'SYSTEM_CONFIG';
                            final initial = dept['title']?.toString().substring(0, 1).toUpperCase() ?? 'D';
                            final avatarColor = isSystem
                                ? Colors.grey
                                : Color(0xFF000000 + (displayTitle.hashCode & 0xFFFFFF)).withOpacity(1);

                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DepartmentQuestionsScreen(
                                        departmentId: dept['id'],
                                        departmentName: displayTitle,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: avatarColor.withOpacity(0.15),
                                        child: Text(
                                          initial,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: avatarColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Title + description
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayTitle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF1A2F4B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (description.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                description,
                                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            if (category.isNotEmpty && category != 'SYSTEM') ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  category,
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Delete button
                                      InkWell(
                                        onTap: () => _deleteDepartment(dept['id']),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                                        ),
                                      ),
                                      // Chevron
                                      Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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
