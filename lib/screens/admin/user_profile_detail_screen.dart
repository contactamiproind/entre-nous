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

    Map<String, dynamic>? profileResponse;
    List<Map<String, dynamic>> assignmentsResponse = [];
    Map<String, dynamic>? progressResponse;
    List<Map<String, dynamic>> pathwaysResponse = [];

    try {
      // Load user profile - handle errors separately
      try {
        profileResponse = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_id', widget.userId)
            .maybeSingle();
      } catch (e) {
        debugPrint('Error loading profile (non-fatal): $e');
        // Continue even if profile fails
      }

      // Load pathway assignments
      debugPrint('Loading assignments for user: ${widget.userId}');
      assignmentsResponse = List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .from('usr_dept')
            .select('*, departments(*)')
            .eq('user_id', widget.userId)
      );
      
      debugPrint('Assignments response: $assignmentsResponse');
      debugPrint('Assignments count: ${assignmentsResponse.length}');

      // Load user progress - query from usr_dept for summary
      try {
        progressResponse = await Supabase.instance.client
            .from('usr_dept')
            .select()
            .eq('user_id', widget.userId)
            .eq('is_current', true)
            .maybeSingle();
      } catch (e) {
        debugPrint('Error loading progress (non-fatal): $e');
        // Continue even if progress fails
      }

      // Load all available pathways - CRITICAL for assignment functionality
      try {
        pathwaysResponse = List<Map<String, dynamic>>.from(
          await Supabase.instance.client
              .from('departments')
              .select()
              .order('title')
        );
        debugPrint('Loaded ${pathwaysResponse.length} pathways');
      } catch (e) {
        debugPrint('Error loading pathways: $e');
        // This is critical - show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading pathways: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() {
        _userProfile = profileResponse;
        _pathwayAssignments = assignmentsResponse;
        _userProgress = progressResponse;
        _availablePathways = pathwaysResponse;
        _isLoading = false;
      });
      
      debugPrint('State updated. Assignments: ${_pathwayAssignments.length}');
    } catch (e, stackTrace) {
      debugPrint('Error loading user data: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Still set whatever data we managed to load
      setState(() {
        _userProfile = profileResponse;
        _pathwayAssignments = assignmentsResponse;
        _userProgress = progressResponse;
        _availablePathways = pathwaysResponse;
        _isLoading = false;
      });
      
      // Don't show error to user if assignments loaded successfully
      // The profile error is non-critical
    }
  }

  Future<void> _assignPathway(String pathwayId, String pathwayTitle) async {
    try {
      final admin = Supabase.instance.client.auth.currentUser;
      if (admin == null) return;

      // Assign pathway with questions using database function
      await Supabase.instance.client.rpc(
        'assign_pathway_with_questions',
        params: {
          'p_user_id': widget.userId,
          'p_dept_id': pathwayId,
          'p_assigned_by': admin.id,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pathway assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Wait a moment for database transaction to complete
      await Future.delayed(const Duration(milliseconds: 500));
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
            .from('usr_dept')
            .delete()
            .eq('user_id', widget.userId)
            .eq('dept_id', assignment['dept_id']);

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

  Future<void> _resetPathwayProgress(Map<String, dynamic> assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Pathway Progress'),
        content: Text(
          'Are you sure you want to reset progress for "${assignment['departments']?['title'] ?? 'this pathway'}"? \n\nThis will clear all answers and set the level back to 1.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from usr_progress
        await Supabase.instance.client
            .from('usr_progress')
            .delete()
            .eq('usr_dept_id', assignment['id']); // Assuming 'id' is usr_dept primary key

        // Update usr_dept
        await Supabase.instance.client
            .from('usr_dept')
            .update({
              'current_level': 1,
              'completed_levels': 0,
              // 'updated_at': DateTime.now().toIso8601String(), // Trigger should handle this
            })
            .eq('id', assignment['id']);

        // Cascade Reset Logic
        final title = assignment['departments']?['title'];
        if (title != null) {
          final downstreamTitles = <String>[];
          if (title == 'Orientation') {
            downstreamTitles.addAll(['Process', 'SOP', 'End Game']);
          } else if (title == 'Process') {
            downstreamTitles.addAll(['SOP', 'End Game']);
          } else if (title == 'SOP') {
             downstreamTitles.add('End Game');
          }

          if (downstreamTitles.isNotEmpty) {
             // Find assignments for downstream titles
             for (var downstreamTitle in downstreamTitles) {
               final downstreamAssignment = _pathwayAssignments.firstWhere(
                 (a) => a['departments']?['title'] == downstreamTitle,
                 orElse: () => {},
               );
               
               if (downstreamAssignment.isNotEmpty) {
                  // Reset downstream progress
                  await Supabase.instance.client
                      .from('usr_progress')
                      .delete()
                      .eq('usr_dept_id', downstreamAssignment['id']);
                  
                  await Supabase.instance.client
                      .from('usr_dept')
                      .update({
                        'current_level': 1,
                        'completed_levels': 0,
                      })
                      .eq('id', downstreamAssignment['id']);
               }
             }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pathway progress reset successfully!'),
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

  Future<void> _reassignPathway(Map<String, dynamic> currentAssignment) async {
    // Show ALL pathways (except SYSTEM_CONFIG) so user can re-assign/reset any of them
    final targetPathways = _availablePathways
        .where((p) => p['title'] != 'SYSTEM_CONFIG') // Only exclude System Config
        .toList();

    if (targetPathways.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pathways available')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reassign Pathway'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select pathway to assign and reset:'),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: targetPathways.length,
                  itemBuilder: (dialogContext, index) { // Using dialogContext here too or just context is fine if not used
                    final pathway = targetPathways[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        title: Text(
                          pathway['title'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          pathway['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        trailing: IconButton(
                        icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                        onPressed: () async {
                           // Confirm Reassign
                           final confirmReassign = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Assign'),
                                content: Text('Are you sure you want to assign "${pathway['title']}"? \n\nExisting progress for this pathway will be reset.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Assign'),
                                  ),
                                ],
                              )
                           );

                           if (confirmReassign == true) {
                             if (context.mounted) Navigator.pop(dialogContext); // Close selection list
                             
                             // EXECUTE REASSIGN
                             try {
                                final adminId = Supabase.instance.client.auth.currentUser?.id;
                                
                                // 0. Check if assignment already exists
                                final existingAssignment = await Supabase.instance.client
                                    .from('usr_dept')
                                    .select('id')
                                    .eq('user_id', widget.userId)
                                    .eq('dept_id', pathway['id'])
                                    .maybeSingle();

                                if (existingAssignment == null) {
                                  // 1. Assign new pathway if not exists
                                  await Supabase.instance.client.rpc(
                                    'assign_pathway_with_questions',
                                    params: {
                                      'p_user_id': widget.userId,
                                      'p_dept_id': pathway['id'],
                                      'p_assigned_by': adminId,
                                    },
                                  );
                                }
                                
                                // 3. Find and Reset the NEW assignment so user can solve it again
                                final newAssignmentRes = await Supabase.instance.client
                                    .from('usr_dept')
                                    .select('id')
                                    .eq('user_id', widget.userId)
                                    .eq('dept_id', pathway['id'])
                                    .maybeSingle();

                                if (newAssignmentRes != null) {
                                   final newId = newAssignmentRes['id'];
                                   
                                   // Reset progress for this new assignment
                                   await Supabase.instance.client
                                      .from('usr_progress')
                                      .delete()
                                      .eq('usr_dept_id', newId);
                                    
                                   await Supabase.instance.client
                                      .from('usr_dept')
                                      .update({
                                        'current_level': 1,
                                        'completed_levels': 0,
                                        'is_current': true // Ensure it is active
                                      })
                                      .eq('id', newId);
                                }
                                
                                // 3. Ensure new is set to active (just to be safe if RPC doesn't force it)
                                // We might need to find the new assignment ID first, but usually RPC handles it.
                                // For now, let's assume RPC does its job or we refresh.

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Pathway "${pathway['title']}" assigned and reset successfully!'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  _loadUserData();
                                }
                             } catch (e) {
                               debugPrint('Reassign error: $e');
                               if (mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Reassign failed: $e'), backgroundColor: Colors.red),
                                 );
                               }
                             }
                           }
                        },
                      ),
                    ),
                  );
                },
                ),
              ),
            ],
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

  void _showAssignPathwayDialog() {
    // Get departments not yet assigned
    debugPrint('Total pathways available: ${_availablePathways.length}');
    debugPrint('Total assignments: ${_pathwayAssignments.length}');
    
    final assignedDeptIds = _pathwayAssignments.map((a) => a['dept_id']).toSet();
    debugPrint('Assigned dept IDs: $assignedDeptIds');
    
    final unassignedPathways = _availablePathways
        .where((p) => !assignedDeptIds.contains(p['id']) && p['title'] != 'SYSTEM_CONFIG')
        .toList();
    
    debugPrint('Unassigned pathways: ${unassignedPathways.length}');

    if (unassignedPathways.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All pathways already assigned')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unassignedPathways.length,
            itemBuilder: (context, index) {
              final pathway = unassignedPathways[index];
              final title = pathway['title'] ?? 'Unknown';
              final category = pathway['category'];
              final displayTitle = (title == 'General' && category != null)
                  ? 'General ($category)'
                  : title;

              return ListTile(
                title: Text(displayTitle),
                subtitle: Text(pathway['description'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                    _assignPathway(pathway['id'], displayTitle);
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
      child: Container(
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('User Profile: ${widget.userEmail}'),
            backgroundColor: const Color(0xFFF4EF8B),
            foregroundColor: Colors.black,
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
                                const Expanded(
                                  child: Text(
                                    'Pathway Assignments',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A2F4B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      // Top Row: Icon + Title + Active Status
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.school_rounded,
                                              color: assignment['is_current'] == true
                                                  ? Colors.green
                                                  : Colors.grey,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    pathway?['title'] ?? 'Unknown',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    assignment['is_current'] == true
                                                        ? 'Current Pathway'
                                                        : 'Assigned',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (assignment['is_current'] == true)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: Colors.green),
                                                ),
                                                child: const Text(
                                                  'ACTIVE',
                                                  style: TextStyle(
                                                    color: Colors.green, 
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      // Bottom Row: Actions
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        child: Wrap(
                                          alignment: WrapAlignment.end,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            // Reset Button
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.restart_alt, size: 16, color: Colors.orange),
                                              label: const Text('Reset', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                              onPressed: () => _resetPathwayProgress(assignment),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                side: const BorderSide(color: Colors.orange),
                                              ),
                                            ),
                                            // Reassign Button
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.swap_horiz, size: 16, color: Colors.blue),
                                              label: const Text('Reassign', style: TextStyle(color: Colors.blue, fontSize: 12)),
                                              onPressed: () => _reassignPathway(assignment),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                side: const BorderSide(color: Colors.blue),
                                              ),
                                            ),
                                            // Delete Button
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              onPressed: () => _deletePathway(assignment),
                                              tooltip: 'Remove Pathway',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              style: IconButton.styleFrom(
                                                padding: const EdgeInsets.all(8),
                                              ),
                                            ),
                                          ],
                                        ),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (label == 'User ID') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2F4B),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.black87, 
                          fontFamily: 'monospace',
                          fontSize: 12
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('User ID copied to clipboard')), // Placeholder logic
                         );
                      },
                      child: const Icon(Icons.copy, size: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
