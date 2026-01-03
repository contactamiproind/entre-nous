import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileDetailScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  const UserProfileDetailScreen({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<UserProfileDetailScreen> createState() => _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _pathwayAssignments = [];
  Map<String, dynamic>? _userProgress;
  List<Map<String, dynamic>> _availablePathways = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Load user profile
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', widget.userId)
          .single();

      // Load pathway assignments
      final assignmentsResponse = await Supabase.instance.client
          .from('user_pathway')
          .select('*, departments(*)')
          .eq('user_id', widget.userId);

      // Load user progress
      final progressResponse = await Supabase.instance.client
          .from('user_progress')
          .select()
          .eq('user_id', widget.userId)
          .maybeSingle();

      // Load all available pathways
      final pathwaysResponse = await Supabase.instance.client
          .from('departments')
          .select()
          .order('title');

      setState(() {
        _userProfile = profileResponse;
        _pathwayAssignments = List<Map<String, dynamic>>.from(assignmentsResponse);
        _userProgress = progressResponse;
        _availablePathways = List<Map<String, dynamic>>.from(pathwaysResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignPathway(String pathwayId, String pathwayTitle) async {
    try {
      final admin = Supabase.instance.client.auth.currentUser;
      if (admin == null) return;

      // Assign pathway
      await Supabase.instance.client.from('user_pathway').insert({
        'user_id': widget.userId,
        'pathway_id': pathwayId,
        'pathway_name': pathwayTitle,
        'assigned_by': admin.id,
        'assigned_at': DateTime.now().toIso8601String(),
        'is_current': _pathwayAssignments.isEmpty,
      });


      // Initialize user progress (always create/update for assigned pathway)
      await Supabase.instance.client.from('user_progress').upsert({
        'user_id': widget.userId,
        'current_pathway_id': pathwayId,
        'current_level': 1,
        'total_score': 0,
      }, onConflict: 'user_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pathway assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadUserData();
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

  Future<void> _deletePathway(Map<String, dynamic> assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pathway Assignment'),
        content: Text(
          'Are you sure you want to remove "${assignment['departments']?['title'] ?? 'this pathway'}" from this user?',
        ),
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
        // Delete pathway assignment
        await Supabase.instance.client
            .from('user_pathway')
            .delete()
            .eq('user_id', widget.userId)
            .eq('pathway_id', assignment['pathway_id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pathway assignment removed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadUserData();
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

  void _showAssignPathwayDialog() {
    // Get pathways not yet assigned
    final assignedPathwayIds = _pathwayAssignments.map((a) => a['pathway_id']).toSet();
    final unassignedPathways = _availablePathways
        .where((p) => !assignedPathwayIds.contains(p['id']))
        .toList();

    if (unassignedPathways.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All pathways already assigned')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Pathway'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unassignedPathways.length,
            itemBuilder: (context, index) {
              final pathway = unassignedPathways[index];
              return ListTile(
                title: Text(pathway['title'] ?? 'Unknown'),
                subtitle: Text(pathway['description'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                    _assignPathway(pathway['id'], pathway['title']);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text('User Profile: ${widget.userEmail}'),
          backgroundColor: const Color(0xFF1A2F4B),
          foregroundColor: Colors.white,
          toolbarHeight: 60,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'User Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2F4B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Email', widget.userEmail),
                            _buildInfoRow('Role', _userProfile?['role'] ?? 'N/A'),
                            _buildInfoRow('User ID', widget.userId),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pathway Assignments Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pathway Assignments',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2F4B),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: _showAssignPathwayDialog,
                                  tooltip: 'Assign Pathway',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_pathwayAssignments.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Icon(Icons.route_outlined, size: 64, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'No pathways assigned',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._pathwayAssignments.map((assignment) {
                                final pathway = assignment['departments'];
                                return ListTile(
                                  leading: Icon(
                                    Icons.school_rounded,
                                    color: assignment['is_current'] == true
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  title: Text(pathway?['title'] ?? 'Unknown'),
                                  subtitle: Text(
                                    assignment['is_current'] == true
                                        ? 'Current Pathway'
                                        : 'Assigned',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (assignment['is_current'] == true)
                                        const Chip(
                                          label: Text('ACTIVE'),
                                          backgroundColor: Colors.green,
                                          labelStyle: TextStyle(color: Colors.white),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deletePathway(assignment),
                                        tooltip: 'Remove Pathway',
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Progress Stats Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Progress Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2F4B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_userProgress == null)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'No progress data available',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else ...[
                              _buildInfoRow('Current Level', _userProgress!['current_level']?.toString() ?? 'N/A'),
                              _buildInfoRow('Completed Assignments', _userProgress!['completed_assignments']?.toString() ?? '0'),
                              _buildInfoRow('Last Updated', _userProgress!['updated_at'] ?? 'N/A'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80), // Extra padding for bottom nav
                  ],
                ),
              ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A2F4B).withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: 0, // No specific tab selected
            onTap: (index) {
              Navigator.pop(context);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1A2F4B),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2F4B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
