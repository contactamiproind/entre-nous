import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/department.dart';

class DepartmentService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Get all departments
  Future<List<Department>> getAllDepartments() async {
    try {
      final response = await _supabase
          .from('departments')
          .select()
          .order('title');

      return (response as List)
          .map((json) => Department.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load departments: $e');
    }
  }

  // Get department by ID
  Future<Department?> getDepartmentById(String departmentId) async {
    try {
      final response = await _supabase
          .from('departments')
          .select()
          .eq('id', departmentId)
          .single();

      return Department.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get distinct levels for a department (derived from questions table)
  // Levels are integers 1-4 on the questions table; there is no separate dept_levels table.
  Future<List<int>> getDepartmentLevels(String departmentId) async {
    try {
      final response = await _supabase
          .from('questions')
          .select('level')
          .eq('dept_id', departmentId);

      final levels = (response as List)
          .map((json) => json['level'] as int? ?? 1)
          .toSet()
          .toList()
        ..sort();
      return levels;
    } catch (e) {
      throw Exception('Failed to load department levels: $e');
    }
  }

  // Admin: Create a new department
  Future<Department> createDepartment({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _supabase
          .from('departments')
          .insert({
            'title': name,
            'description': description,
          })
          .select()
          .single();

      return Department.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create department: $e');
    }
  }

  // Admin: Update department
  Future<void> updateDepartment({
    required String departmentId,
    String? name,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['title'] = name;
      if (description != null) updateData['description'] = description;

      await _supabase
          .from('departments')
          .update(updateData)
          .eq('id', departmentId);
    } catch (e) {
      throw Exception('Failed to update department: $e');
    }
  }

  // Admin: Delete department
  Future<void> deleteDepartment(String departmentId) async {
    try {
      await _supabase
          .from('departments')
          .delete()
          .eq('id', departmentId);
    } catch (e) {
      throw Exception('Failed to delete department: $e');
    }
  }

  // NOTE: dept_levels table does not exist. Levels are integers 1-4 on the questions table.
  // Level management is done by setting the 'level' field on individual questions.

  // Check if user has completed orientation
  Future<bool> isOrientationCompleted(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('orientation_completed')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      return response['orientation_completed'] ?? false;
    } catch (e) {
      throw Exception('Failed to check orientation status: $e');
    }
  }

  // Mark orientation as completed
  Future<void> markOrientationComplete(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .update({'orientation_completed': true})
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to mark orientation complete: $e');
    }
  }

  // Get Orientation department
  Future<Department?> getOrientationDepartment() async {
    try {
      final response = await _supabase
          .from('departments')
          .select()
          .eq('title', 'Orientation')
          .maybeSingle();

      if (response == null) return null;
      return Department.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get orientation department: $e');
    }
  }
}
