import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_assignment.dart';

class AssignmentService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Get all assignments for a user
  Future<List<UserAssignment>> getUserAssignments(String userId) async {
    try {
      final response = await _supabase
          .from('user_pathway')
          .select('''
            *,
            departments!inner(title)
          ''')
          .eq('user_id', userId)
          .order('assigned_at', ascending: false);

      return (response as List)
          .map((json) {
            // Add pathway name from the joined departments table
            if (json['departments'] != null) {
              json['pathway_name'] = json['departments']['title'];
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
          .from('user_pathway')
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
          .from('user_pathway')
          .select('''
            *,
            departments!inner(title)
          ''')
          .order('assigned_at', ascending: false);

      return (response as List)
          .map((json) {
            // Add pathway name from the joined departments table
            if (json['departments'] != null) {
              json['pathway_name'] = json['departments']['title'];
            }
            return UserAssignment.fromJson(json);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to load all assignments: $e');
    }
  }

  // Admin: Create a new assignment for a user
  Future<UserAssignment> createAssignment({
    required String userId,
    required String assignmentName,
    bool orientationCompleted = false,
    int marks = 0,
    int maxMarks = 100,
  }) async {
    try {
      final response = await _supabase
          .from('user_pathway')
          .insert({
            'user_id': userId,
            'pathway_name': assignmentName,
            'is_current': true,
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
      if (assignmentName != null) updateData['pathway_name'] = assignmentName;

      await _supabase
          .from('user_pathway')
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
          .from('user_pathway')
          .update({
            'is_current': false,
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
          .from('user_pathway')
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
