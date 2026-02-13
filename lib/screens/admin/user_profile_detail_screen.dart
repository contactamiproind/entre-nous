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
            .order('assigned_at', ascending: true)
      );
      
      debugPrint('Assignments response: $assignmentsResponse');
      debugPrint('Assignments count: ${assignmentsResponse.length}');

      // Load all available departments - CRITICAL for assignment functionality
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

      // Expand assignments by actual level_number from usr_progress
      // A single usr_dept may have questions at multiple levels
      final expandedAssignments = await _expandAssignmentsByLevel(assignmentsResponse);

      setState(() {
        _userProfile = profileResponse;
        _pathwayAssignments = expandedAssignments;
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
        _availablePathways = pathwaysResponse;
        _isLoading = false;
      });
      
      // Don't show error to user if assignments loaded successfully
      // The profile error is non-critical
    }
  }

  /// Expand usr_dept records by actual level_number from usr_progress.
  /// If a single usr_dept has questions at level 1 AND level 2, this creates
  /// two virtual records so the UI groups them correctly.
  Future<List<Map<String, dynamic>>> _expandAssignmentsByLevel(
      List<Map<String, dynamic>> assignments) async {
    final List<Map<String, dynamic>> expanded = [];

    for (final record in assignments) {
      final usrDeptId = record['id'];

      List progressRecords = [];
      try {
        progressRecords = await Supabase.instance.client
            .from('usr_progress')
            .select('question_id, status, level_number, score_earned')
            .eq('usr_dept_id', usrDeptId)
            .order('created_at', ascending: true);
      } catch (e) {
        debugPrint('Error loading progress for expansion: $e');
      }

      if (progressRecords.isEmpty) {
        expanded.add(record);
        continue;
      }

      // Group by level_number
      final Map<int, List<dynamic>> byLevel = {};
      for (final pr in progressRecords) {
        final lvl = pr['level_number'] is int
            ? pr['level_number'] as int
            : (record['current_level'] as int? ?? 1);
        byLevel.putIfAbsent(lvl, () => []);
        byLevel[lvl]!.add(pr);
      }

      if (byLevel.length <= 1) {
        // Single level — update current_level to match actual data
        final actualLevel = byLevel.keys.first;
        final questions = byLevel[actualLevel]!;
        final totalQ = questions.length;
        final answeredQ = questions.where((p) => p['status'] == 'answered').length;
        final correctQ = questions.where((p) => p['status'] == 'answered' && (p['score_earned'] as int? ?? 0) > 0).length;
        final totalScore = questions.fold<int>(0, (sum, p) => sum + (p['score_earned'] as int? ?? 0));
        final updatedRecord = Map<String, dynamic>.from(record);
        updatedRecord['current_level'] = actualLevel;
        updatedRecord['total_questions'] = totalQ;
        updatedRecord['answered_questions'] = answeredQ;
        updatedRecord['correct_answers'] = correctQ;
        updatedRecord['total_score'] = totalScore;
        expanded.add(updatedRecord);
      } else {
        // Multiple levels — create a virtual record per level
        final sortedLevels = byLevel.keys.toList()..sort();
        for (final lvl in sortedLevels) {
          final questions = byLevel[lvl]!;
          final totalQ = questions.length;
          final answeredQ = questions.where((p) => p['status'] == 'answered').length;
          final correctQ = questions.where((p) => p['status'] == 'answered' && (p['score_earned'] as int? ?? 0) > 0).length;
          final totalScore = questions.fold<int>(0, (sum, p) => sum + (p['score_earned'] as int? ?? 0));
          final maxScore = totalQ * 10; // Approximate max score

          final virtualRecord = Map<String, dynamic>.from(record);
          virtualRecord['current_level'] = lvl;
          virtualRecord['total_questions'] = totalQ;
          virtualRecord['answered_questions'] = answeredQ;
          virtualRecord['correct_answers'] = correctQ;
          virtualRecord['total_score'] = totalScore;
          virtualRecord['max_possible_score'] = maxScore;
          expanded.add(virtualRecord);
          debugPrint('📊 Admin expand: L$lvl $answeredQ/$totalQ correct=$correctQ score=$totalScore');
        }
      }
    }

    return expanded;
  }

  Future<void> _assignDepartment({
    required String deptId,
    required String deptName,
    required int level,
    required int numQuestions,
    required int totalInBank,
    required List<Map<String, dynamic>> selectedQuestions,
  }) async {
    int successCount = 0;
    try {
      final admin = Supabase.instance.client.auth.currentUser;
      if (admin == null) return;

      // 1. Check if usr_dept already exists for this user+dept
      var usrDeptRecord = await Supabase.instance.client
          .from('usr_dept')
          .select('id')
          .eq('user_id', widget.userId)
          .eq('dept_id', deptId)
          .maybeSingle();

      String usrDeptId;

      if (usrDeptRecord == null) {
        // Create new usr_dept record
        final inserted = await Supabase.instance.client
            .from('usr_dept')
            .insert({
              'user_id': widget.userId,
              'dept_id': deptId,
              'dept_name': deptName,
              'assigned_by': admin.id,
              'total_levels': 4,
              'current_level': level,
              'started_at': DateTime.now().toIso8601String(),
              'status': 'active',
              'is_current': true,
            })
            .select('id')
            .single();
        usrDeptId = inserted['id'];
      } else {
        usrDeptId = usrDeptRecord['id'];
      }

      // 2. Insert usr_progress records for each randomly selected question
      for (final question in selectedQuestions) {
        try {
          await Supabase.instance.client.from('usr_progress').insert({
            'user_id': widget.userId,
            'dept_id': deptId,
            'usr_dept_id': usrDeptId,
            'question_id': question['id'],
            'question_text': question['title'] ?? 'Question',
            'question_type': question['description'] ?? '',
            'category': deptName,
            'points': question['points'] ?? 10,
            'level_number': level,
            'level_name': 'Level $level',
            'status': 'pending',
          });
          successCount++;
        } catch (e) {
          debugPrint('Failed to insert question ${question['id']}: $e');
        }
      }

      // Show summary dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  successCount > 0 ? Icons.check_circle : Icons.error,
                  color: successCount > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text('Assignment Summary'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Department: $deptName'),
                Text('Level: $level'),
                const SizedBox(height: 12),
                Text(
                  '$successCount out of $totalInBank questions successfully assigned',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (successCount < numQuestions)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${numQuestions - successCount} questions failed to assign (may already be assigned)',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 300));
      _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning: $e'),
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
        title: const Text('Delete Department Assignment'),
        content: Text(
          'Are you sure you want to remove "${assignment['departments']?['title'] ?? 'this department'}" from this user?',
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
              content: Text('Department assignment removed successfully!'),
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
    final deptName = _buildDeptDisplayName(assignment['departments']);
    final assignmentLevel = assignment['current_level'] as int? ?? 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Course Progress'),
        content: Text(
          'Reset answers and points for "$deptName" (Level $assignmentLevel)?\n\n'
          'The user will be able to retake this course. Questions will remain assigned.',
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
        final usrDeptId = assignment['id'];

        // Reset usr_progress: clear answers & points but KEEP the question assignments
        await Supabase.instance.client
            .from('usr_progress')
            .update({
              'status': 'pending',
              'score_earned': 0,
              'user_answer': null,
              'attempt_count': 0,
            })
            .eq('usr_dept_id', usrDeptId)
            .eq('level_number', assignmentLevel);

        // Update usr_dept counters (don't change current_level or completed_levels)
        await Supabase.instance.client
            .from('usr_dept')
            .update({
              'answered_questions': 0,
              'correct_answers': 0,
              'total_score': 0,
            })
            .eq('id', usrDeptId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Progress reset for "$deptName" (Level $assignmentLevel)'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadUserData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        const SnackBar(content: Text('No departments available')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reassign Department'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select department to assign and reset:'),
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
                                content: Text('Are you sure you want to assign "${pathway['title']}"? \n\nExisting progress for this department will be reset.'),
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
                                      content: Text('Department "${pathway['title']}" assigned and reset successfully!'),
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

  /// Toggle level completion for all usr_dept records.
  /// Only updates completed_levels — never changes current_level (which is the assigned level).
  /// Also updates the user's profile level to reflect the new highest completed level + 1.
  Future<void> _toggleLevelComplete(int level, bool markComplete) async {
    try {
      final newCompletedLevels = markComplete ? level : level - 1;

      // Update ALL usr_dept records for this user to reflect the new completed_levels
      for (final assignment in _pathwayAssignments) {
        await Supabase.instance.client
            .from('usr_dept')
            .update({'completed_levels': newCompletedLevels})
            .eq('id', assignment['id']);
      }

      // Update user profile level to next unlocked level
      final newProfileLevel = (newCompletedLevels + 1).clamp(1, 4);
      await Supabase.instance.client
          .from('profiles')
          .update({'level': newProfileLevel})
          .eq('user_id', widget.userId);

      _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Get the max completed level across all assignments for this user
  int _getMaxCompletedLevel() {
    int maxCompleted = 0;
    for (final a in _pathwayAssignments) {
      final cl = a['completed_levels'] as int? ?? 0;
      if (cl > maxCompleted) maxCompleted = cl;
    }
    return maxCompleted;
  }

  /// Build display name for a department
  String _buildDeptDisplayName(Map<String, dynamic>? dept) {
    if (dept == null) return 'Unknown';
    final title = dept['title'] as String? ?? 'Unknown';
    final category = dept['category'] as String?;
    if (title == 'General' && category != null && category.isNotEmpty) {
      return 'General ($category)';
    }
    return title;
  }

  /// Build a compact stat chip for assignment cards
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDepartmentDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _AssignDepartmentDialog(
        userId: widget.userId,
        onAssign: ({
          required String deptId,
          required String deptName,
          required int level,
          required int numQuestions,
          required int totalInBank,
          required List<Map<String, dynamic>> selectedQuestions,
        }) {
          Navigator.pop(dialogContext);
          _assignDepartment(
            deptId: deptId,
            deptName: deptName,
            level: level,
            numQuestions: numQuestions,
            totalInBank: totalInBank,
            selectedQuestions: selectedQuestions,
          );
        },
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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: AppBar(
              backgroundColor: const Color(0xFFF4EF8B),
              foregroundColor: const Color(0xFF1A2F4B),
              elevation: 0,
              toolbarHeight: 44,
              titleSpacing: 0,
              leading: InkWell(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.arrow_back, size: 20),
                ),
              ),
              title: Text(
                widget.userEmail,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact User Info Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: (_userProfile?['role'] == 'admin')
                                ? const Color(0xFFF08A7E).withOpacity(0.15)
                                : const Color(0xFF6BCB9F).withOpacity(0.15),
                            child: Icon(
                              (_userProfile?['role'] == 'admin')
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              size: 18,
                              color: (_userProfile?['role'] == 'admin')
                                  ? const Color(0xFFF08A7E)
                                  : const Color(0xFF6BCB9F),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userEmail,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF1A2F4B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Role badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (_userProfile?['role'] == 'admin')
                                            ? const Color(0xFFF08A7E).withOpacity(0.12)
                                            : const Color(0xFF6BCB9F).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (_userProfile?['role'] ?? 'user').toString().toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: (_userProfile?['role'] == 'admin')
                                              ? const Color(0xFFF08A7E)
                                              : const Color(0xFF6BCB9F),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Level badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A2F4B).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Level ${_userProfile?['level'] ?? 1}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A2F4B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Copy User ID
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User ID copied')),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy, size: 12, color: Colors.grey[400]),
                                  const SizedBox(width: 2),
                                  Text('ID', style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Departments Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Departments',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2F4B),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: FloatingActionButton(
                                  onPressed: _showAssignDepartmentDialog,
                                  backgroundColor: Colors.green,
                                  elevation: 1,
                                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                            // Level-grouped assignments
                            ...List.generate(4, (index) {
                              final level = index + 1;
                              final maxCompleted = _getMaxCompletedLevel();
                              final isLevelCompleted = level <= maxCompleted;
                              final isLevelUnlocked = level <= maxCompleted + 1;

                              // Get assignments at this level
                              final levelAssignments = _pathwayAssignments.where((a) {
                                return (a['current_level'] as int? ?? 1) == level;
                              }).toList();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isLevelCompleted
                                        ? Colors.green.shade300
                                        : isLevelUnlocked
                                            ? Colors.blue.shade200
                                            : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: !isLevelUnlocked ? Colors.grey.shade50 : Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    // Level Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isLevelCompleted
                                            ? Colors.green.shade50
                                            : isLevelUnlocked
                                                ? const Color(0xFFF0F4FF)
                                                : Colors.grey.shade100,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(11),
                                          topRight: Radius.circular(11),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isLevelCompleted
                                                ? Icons.check_circle
                                                : isLevelUnlocked
                                                    ? Icons.play_circle_outline
                                                    : Icons.lock,
                                            color: isLevelCompleted
                                                ? Colors.green
                                                : isLevelUnlocked
                                                    ? const Color(0xFF1A2F4B)
                                                    : Colors.grey,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Level $level',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isLevelUnlocked ? const Color(0xFF1A2F4B) : Colors.grey,
                                            ),
                                          ),
                                          if (isLevelCompleted)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'COMPLETED',
                                                style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          if (!isLevelUnlocked)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'LOCKED',
                                                style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          const Spacer(),
                                          // Toggle complete/incomplete
                                          if (isLevelUnlocked)
                                            Tooltip(
                                              message: isLevelCompleted ? 'Mark as incomplete' : 'Mark as complete',
                                              child: Switch(
                                                value: isLevelCompleted,
                                                activeColor: Colors.green,
                                                onChanged: (val) => _toggleLevelComplete(level, val),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Assignments under this level
                                    if (levelAssignments.isEmpty && isLevelUnlocked)
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          'No assignments at this level',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                                        ),
                                      )
                                    else if (!isLevelUnlocked)
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          'Complete Level ${level - 1} to unlock',
                                          style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic),
                                        ),
                                      )
                                    else
                                      ...levelAssignments.map((assignment) {
                                        final dept = assignment['departments'];
                                        final deptName = _buildDeptDisplayName(dept);
                                        final totalQ = assignment['total_questions'] as int? ?? 0;
                                        final answeredQ = assignment['answered_questions'] as int? ?? 0;
                                        final correctQ = assignment['correct_answers'] as int? ?? 0;
                                        final totalScore = assignment['total_score'] as int? ?? 0;
                                        final maxScore = assignment['max_possible_score'] as int? ?? 0;
                                        final progress = totalQ > 0 ? answeredQ / totalQ : 0.0;
                                        final allAnswered = totalQ > 0 && answeredQ >= totalQ;

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Dept name + status
                                              Row(
                                                children: [
                                                  Icon(Icons.school_rounded, size: 20, color: Colors.blueGrey.shade400),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      deptName,
                                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                    ),
                                                  ),
                                                  if (allAnswered)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.green.shade300),
                                                      ),
                                                      child: const Text(
                                                        'DONE',
                                                        style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                                                      ),
                                                    )
                                                  else if (assignment['status'] == 'active')
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.blue.shade300),
                                                      ),
                                                      child: const Text(
                                                        'IN PROGRESS',
                                                        style: TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Progress bar
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor: Colors.grey.shade200,
                                                  color: progress >= 1.0 ? Colors.green : const Color(0xFF1A2F4B),
                                                  minHeight: 6,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              // Detailed stats row
                                              Row(
                                                children: [
                                                  // Attempted
                                                  _buildStatChip(
                                                    icon: Icons.quiz_outlined,
                                                    label: 'Attempted',
                                                    value: '$answeredQ / $totalQ',
                                                    color: const Color(0xFF1A2F4B),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Correct
                                                  _buildStatChip(
                                                    icon: Icons.check_circle_outline,
                                                    label: 'Correct',
                                                    value: '$correctQ / $totalQ',
                                                    color: correctQ == totalQ && totalQ > 0 ? Colors.green : Colors.orange,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Score
                                                  _buildStatChip(
                                                    icon: Icons.star_outline,
                                                    label: 'Score',
                                                    value: '$totalScore / $maxScore',
                                                    color: totalScore >= maxScore && maxScore > 0 ? Colors.green : Colors.deepPurple,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              // Actions row — frozen for completed levels
                                              if (!isLevelCompleted)
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    if (isLevelUnlocked)
                                                      InkWell(
                                                        onTap: () => _resetPathwayProgress(assignment),
                                                        child: Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.restart_alt, size: 14, color: Colors.orange.shade700),
                                                              const SizedBox(width: 3),
                                                              Text('Reset', style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    if (isLevelUnlocked)
                                                      const SizedBox(width: 8),
                                                    InkWell(
                                                      onTap: () => _deletePathway(assignment),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.delete_outline, size: 14, color: Colors.red.shade400),
                                                            const SizedBox(width: 3),
                                                            Text('Remove', style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
        ),
      ),
    );
  }

}

// ============================================
// ASSIGN DEPARTMENT DIALOG (Cascading: Level → Department → Num Questions)
// ============================================
class _AssignDepartmentDialog extends StatefulWidget {
  final String userId;
  final void Function({
    required String deptId,
    required String deptName,
    required int level,
    required int numQuestions,
    required int totalInBank,
    required List<Map<String, dynamic>> selectedQuestions,
  }) onAssign;

  const _AssignDepartmentDialog({
    required this.userId,
    required this.onAssign,
  });

  @override
  State<_AssignDepartmentDialog> createState() => _AssignDepartmentDialogState();
}

class _AssignDepartmentDialogState extends State<_AssignDepartmentDialog> {
  final _supabase = Supabase.instance.client;

  // Cascading state
  int? _selectedLevel;
  Map<String, dynamic>? _selectedDepartment;
  int _numQuestions = 10;

  // Data lists
  List<Map<String, dynamic>> _availableDepartments = [];
  int _totalAvailableQuestions = 0;

  // Level progression: highest completed level for this user (0 = none completed)
  int _maxCompletedLevel = 0;

  // Loading states
  bool _isLoadingProgress = true;
  bool _isLoadingDepartments = false;
  bool _isLoadingCount = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  /// Load user's max completed level from usr_dept to enforce progression
  Future<void> _loadUserProgress() async {
    setState(() => _isLoadingProgress = true);
    try {
      final response = await _supabase
          .from('usr_dept')
          .select('current_level, completed_levels, status')
          .eq('user_id', widget.userId);

      int maxCompleted = 0;
      for (final record in (response as List)) {
        final completedLevels = record['completed_levels'] as int? ?? 0;
        if (completedLevels > maxCompleted) {
          maxCompleted = completedLevels;
        }
      }

      setState(() {
        _maxCompletedLevel = maxCompleted;
        _isLoadingProgress = false;
      });
    } catch (e) {
      debugPrint('Error loading user progress: $e');
      setState(() {
        _maxCompletedLevel = 0;
        _isLoadingProgress = false;
      });
    }
  }

  /// On level selected, load departments that have questions at this level
  Future<void> _onLevelSelected(int level) async {
    setState(() {
      _selectedLevel = level;
      _selectedDepartment = null;
      _availableDepartments = [];
      _totalAvailableQuestions = 0;
      _isLoadingDepartments = true;
    });

    try {
      // Get distinct dept_ids that have questions at this level
      final questionsAtLevel = await _supabase
          .from('questions')
          .select('dept_id')
          .eq('level', level);

      final deptIds = (questionsAtLevel as List)
          .map((r) => r['dept_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      if (deptIds.isEmpty) {
        setState(() {
          _availableDepartments = [];
          _isLoadingDepartments = false;
        });
        return;
      }

      // Load department details for those IDs
      final departments = await _supabase
          .from('departments')
          .select('id, title, category')
          .inFilter('id', deptIds)
          .order('title');

      setState(() {
        _availableDepartments = List<Map<String, dynamic>>.from(departments);
        _isLoadingDepartments = false;
      });
    } catch (e) {
      debugPrint('Error loading departments for level: $e');
      setState(() => _isLoadingDepartments = false);
    }
  }

  /// On department selected, count available questions at level+dept
  Future<void> _onDepartmentSelected(Map<String, dynamic> dept) async {
    setState(() {
      _selectedDepartment = dept;
      _totalAvailableQuestions = 0;
      _isLoadingCount = true;
    });

    try {
      final response = await _supabase
          .from('questions')
          .select('id')
          .eq('dept_id', dept['id'])
          .eq('level', _selectedLevel!);

      final count = (response as List).length;

      setState(() {
        _totalAvailableQuestions = count;
        _numQuestions = count > 10 ? 10 : count;
        _isLoadingCount = false;
      });
    } catch (e) {
      debugPrint('Error counting questions: $e');
      setState(() => _isLoadingCount = false);
    }
  }

  /// Build display name for department: "General" → "General (Category)"
  String _deptDisplayName(Map<String, dynamic> dept) {
    final title = dept['title'] as String? ?? 'Unknown';
    final category = dept['category'] as String?;
    if (title == 'General' && category != null && category.isNotEmpty) {
      return 'General ($category)';
    }
    return title;
  }

  /// Execute assignment: randomly pick N questions and call onAssign
  Future<void> _executeAssignment() async {
    if (_selectedDepartment == null || _selectedLevel == null) return;

    setState(() => _isAssigning = true);

    try {
      // Fetch all questions matching level + department
      final allQuestions = await _supabase
          .from('questions')
          .select('id, title, description, points, options, correct_answer')
          .eq('dept_id', _selectedDepartment!['id'])
          .eq('level', _selectedLevel!);

      final questionList = List<Map<String, dynamic>>.from(allQuestions);
      final totalInBank = questionList.length;

      // Shuffle and pick N random questions
      questionList.shuffle();
      final selected = questionList.take(_numQuestions).toList();

      widget.onAssign(
        deptId: _selectedDepartment!['id'],
        deptName: _deptDisplayName(_selectedDepartment!),
        level: _selectedLevel!,
        numQuestions: selected.length,
        totalInBank: totalInBank,
        selectedQuestions: selected,
      );
    } catch (e) {
      debugPrint('Error executing assignment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The assignable level is maxCompletedLevel + 1 (capped at 4)
    final int nextAssignableLevel = _maxCompletedLevel + 1;

    final bool canAssign = _selectedLevel != null &&
        _selectedDepartment != null &&
        _totalAvailableQuestions > 0 &&
        _numQuestions > 0 &&
        !_isAssigning;

    return AlertDialog(
      title: const Text('Assign Department'),
      content: SizedBox(
        width: 360,
        child: _isLoadingProgress
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Level (hardcoded 1-4, progression enforced)
                    const Text('Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    ...List.generate(4, (index) {
                      final level = index + 1;
                      final isEnabled = level <= nextAssignableLevel;
                      final isSelected = _selectedLevel == level;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: isSelected
                              ? const Color(0xFF1A2F4B)
                              : isEnabled
                                  ? Colors.white
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: isEnabled ? () => _onLevelSelected(level) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1A2F4B)
                                      : isEnabled
                                          ? Colors.grey[400]!
                                          : Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : isEnabled
                                            ? const Color(0xFF1A2F4B)
                                            : Colors.grey[400],
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Level $level',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : isEnabled
                                              ? Colors.black87
                                              : Colors.grey[400],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!isEnabled)
                                    Icon(Icons.lock, size: 16, color: Colors.grey[400]),
                                  if (level <= _maxCompletedLevel)
                                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Step 2: Department
                    const Text('Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    if (_selectedLevel == null)
                      const Text('Select a level first', style: TextStyle(color: Colors.grey, fontSize: 12))
                    else if (_isLoadingDepartments)
                      const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                    else if (_availableDepartments.isEmpty)
                      const Text('No departments with questions at this level', style: TextStyle(color: Colors.orange, fontSize: 12))
                    else
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: Icon(Icons.business),
                        ),
                        hint: const Text('Select Department'),
                        value: _selectedDepartment?['id'],
                        items: _availableDepartments.map((dept) {
                          return DropdownMenuItem(
                            value: dept['id'] as String,
                            child: Text(_deptDisplayName(dept), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final dept = _availableDepartments.firstWhere((d) => d['id'] == value);
                            _onDepartmentSelected(dept);
                          }
                        },
                      ),
                    const SizedBox(height: 16),

                    // Step 3: Number of questions
                    const Text('Questions to Assign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    if (_selectedDepartment == null)
                      const Text('Select a department first', style: TextStyle(color: Colors.grey, fontSize: 12))
                    else if (_isLoadingCount)
                      const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                    else if (_totalAvailableQuestions == 0)
                      const Text('No questions available for this combination', style: TextStyle(color: Colors.orange, fontSize: 12))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_totalAvailableQuestions questions available in question bank',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _numQuestions.toDouble(),
                                  min: 1,
                                  max: _totalAvailableQuestions.toDouble(),
                                  divisions: _totalAvailableQuestions > 1 ? _totalAvailableQuestions - 1 : 1,
                                  label: '$_numQuestions',
                                  onChanged: (value) {
                                    setState(() => _numQuestions = value.toInt());
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2F4B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_numQuestions',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: canAssign ? _executeAssignment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A2F4B),
            foregroundColor: Colors.white,
          ),
          child: _isAssigning
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Assign'),
        ),
      ],
    );
  }
}
