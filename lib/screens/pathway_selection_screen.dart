import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pathway_detail_screen.dart';

class DepartmentSelectionScreen extends StatefulWidget {
  const DepartmentSelectionScreen({super.key});

  @override
  State<DepartmentSelectionScreen> createState() => _DepartmentSelectionScreenState();
}

class _DepartmentSelectionScreenState extends State<DepartmentSelectionScreen> {
  List<Map<String, dynamic>> _pathways = [];
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
      if (user == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Only load pathways that are assigned to this user by admin
      final response = await Supabase.instance.client
          .from('usr_dept')
          .select('dept_id, dept_name, departments(*)')
          .eq('user_id', user.id);

      // Extract the departments from the response
      final pathways = response.map((assignment) {
        final dept = assignment['departments'];
        if (dept != null) {
          return {
            'id': assignment['pathway_id'],
            'name': dept['title'] ?? assignment['pathway_name'],
            'description': dept['description'] ?? '',
            'title': dept['title'] ?? assignment['pathway_name'],
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      setState(() {
        _pathways = pathways;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _enrollInDepartment(String pathwayId, String pathwayName) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Check if already enrolled
      final existing = await Supabase.instance.client
          .from('usr_dept')
          .select()
          .eq('user_id', user.id)
          .eq('dept_id', pathwayId)
          .maybeSingle();

      if (existing != null) {
        // Already enrolled, just navigate to pathway detail
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DepartmentDetailScreen(
                pathwayId: pathwayId,
                pathwayName: pathwayName,
              ),
            ),
          );
        }
        return;
      }

      // Enroll user in pathway using RPC function
      await Supabase.instance.client.rpc(
        'assign_pathway_with_questions',
        params: {
          'p_user_id': user.id,
          'p_dept_id': pathwayId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enrolled in $pathwayName!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to pathway detail screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DepartmentDetailScreen(
              pathwayId: pathwayId,
              pathwayName: pathwayName,
            ),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        title: const Text('Choose Your Learning Path'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDepartments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2C3E50),
                        const Color(0xFF3498DB).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select a Pathway',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose your learning journey',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _pathways.length,
                              itemBuilder: (context, index) {
                                final pathway = _pathways[index];
                                return _DepartmentCard(
                                  pathway: pathway,
                                  onEnroll: () => _enrollInDepartment(
                                    pathway['id'],
                                    pathway['name'],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final Map<String, dynamic> pathway;
  final VoidCallback onEnroll;

  const _DepartmentCard({
    required this.pathway,
    required this.onEnroll,
  });

  IconData _getDepartmentIcon(String name) {
    switch (name.toLowerCase()) {
      case 'communication':
        return Icons.chat_bubble_outline;
      case 'creative':
        return Icons.palette_outlined;
      case 'ideation':
        return Icons.lightbulb_outline;
      case 'production':
        return Icons.build_outlined;
      default:
        return Icons.school_outlined;
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
    final color = _getDepartmentColor(pathway['name']);
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getDepartmentIcon(pathway['name']),
                size: 48,
                color: Colors.white,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pathway['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pathway['description'] ?? 'Learn and grow',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onEnroll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Enroll',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
