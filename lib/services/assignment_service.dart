import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_assignment.dart';

class AssignmentService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Get all assignments for a user
  Future<List<UserAssignment>> getUserAssignments(String userId) async {
    try {
      final response = await _supabase
          .from('usr_dept')
          .select('''
            *,
            departments!inner(title)
          ''')
          .eq('user_id', userId)
          .order('assigned_at', ascending: false);

      return (response as List)
          .map((json) {
            // dept_name is already in usr_dept, but keep for compatibility
            if (json['departments'] != null) {
              json['pathway_name'] = json['departments']['title'];
            } else {
              json['pathway_name'] = json['dept_name'];
            }
            return UserAssignment.fromJson(json);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to load assignments: $e');
    }
  }

  // Get a specific assignment
  Future<UserAssignment?> getAssignmentById(String assignmentId) async {
    try {
      final response = await _supabase
          .from('usr_dept')
          .select()
          .eq('id', assignmentId)
          .single();

      return UserAssignment.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Admin: Get all assignments (for all users)
  Future<List<UserAssignment>> getAllAssignments() async {
    try {
      final response = await _supabase
          .from('usr_dept')
          .select('''
            *,
            departments!inner(title)
          ''')
          .order('assigned_at', ascending: false);

      return (response as List)
          .map((json) {
            // dept_name is already in usr_dept, but keep for compatibility
            if (json['departments'] != null) {
              json['pathway_name'] = json['departments']['title'];
            } else {
              json['pathway_name'] = json['dept_name'];
            }
            return UserAssignment.fromJson(json);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to load all assignments: $e');
    }
  }

  // Admin: Assign pathway with questions using database function
  Future<String> assignPathwayWithQuestions({
    required String userId,
    required String deptId,
    String? assignedBy,
  }) async {
    try {
      final result = await _supabase.rpc(
        'assign_pathway_with_questions',
        params: {
          'p_user_id': userId,
          'p_dept_id': deptId,
          'p_assigned_by': assignedBy ?? _supabase.auth.currentUser?.id,
        },
      );
      return result as String; // Returns usr_dept_id
    } catch (e) {
      throw Exception('Failed to assign pathway: $e');
    }
  }

  // Admin: Create a new assignment for a user (legacy - use assignPathwayWithQuestions instead)
  Future<UserAssignment> createAssignment({
    required String userId,
    required String assignmentName,
    bool orientationCompleted = false,
    int marks = 0,
    int maxMarks = 100,
  }) async {
    try {
      final response = await _supabase
          .from('usr_dept')
          .insert({
            'user_id': userId,
            'dept_name': assignmentName,
            'is_current': true,
            'status': 'active',
          })
          .select()
          .single();

      return UserAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create assignment: $e');
    }
  }

  // Admin: Update assignment
  Future<void> updateAssignment({
    required String assignmentId,
    String? assignmentName,
    bool? orientationCompleted,
    int? marks,
    int? maxMarks,
    DateTime? completedAt,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (assignmentName != null) updateData['dept_name'] = assignmentName;
      if (completedAt != null) {
        updateData['completed_at'] = completedAt.toIso8601String();
        updateData['status'] = 'completed';
      }

      await _supabase
          .from('usr_dept')
          .update(updateData)
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Failed to update assignment: $e');
    }
  }

  // Admin: Mark assignment as completed
  Future<void> markAsCompleted(String assignmentId, int marks) async {
    try {
      await _supabase
          .from('usr_dept')
          .update({
            'is_current': false,
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Failed to mark assignment as completed: $e');
    }
  }

  // Admin: Delete assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _supabase
          .from('usr_dept')
          .delete()
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Failed to delete assignment: $e');
    }
  }

  // Check if user has completed orientation
  Future<bool> hasCompletedOrientation(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('orientation_completed')
          .eq('user_id', userId)
          .single();

      return response['orientation_completed'] == true;
    } catch (e) {
      return false;
    }
  }
}
