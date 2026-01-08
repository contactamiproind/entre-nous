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
          .order('name');

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

  // Get levels for a specific department
  Future<List<DepartmentLevel>> getDepartmentLevels(String departmentId) async {
    try {
      final response = await _supabase
          .from('dept_levels')
          .select()
          .eq('dept_id', departmentId)
          .order('level_number', ascending: true);

      return (response as List)
          .map((json) => DepartmentLevel.fromJson(json))
          .toList();
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
            'name': name,
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
      if (name != null) updateData['name'] = name;
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

  // Admin: Create department level
  Future<DepartmentLevel> createDepartmentLevel({
    required String departmentId,
    required int levelNumber,
    required String levelName,
    required int requiredScore,
    String? description,
  }) async {
    try {
      final response = await _supabase
          .from('dept_levels')
          .insert({
            'dept_id': departmentId,
            'level_number': levelNumber,
            'level_name': levelName,
            'required_score': requiredScore,
            'description': description,
          })
          .select()
          .single();

      return DepartmentLevel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create department level: $e');
    }
  }

  // Admin: Update department level
  Future<void> updateDepartmentLevel({
    required String levelId,
    String? levelName,
    int? requiredScore,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (levelName != null) updateData['level_name'] = levelName;
      if (requiredScore != null) updateData['required_score'] = requiredScore;
      if (description != null) updateData['description'] = description;

      await _supabase
          .from('dept_levels')
          .update(updateData)
          .eq('id', levelId);
    } catch (e) {
      throw Exception('Failed to update department level: $e');
    }
  }

  // Admin: Delete department level
  Future<void> deleteDepartmentLevel(String levelId) async {
    try {
      await _supabase
          .from('dept_levels')
          .delete()
          .eq('id', levelId);
    } catch (e) {
      throw Exception('Failed to delete department level: $e');
    }
  }

  // Check if user has completed orientation
  Future<bool> isOrientationCompleted(String userId) async {
    try {
      final response = await _supabase
          .from('usr_progress')
          .select('orientation_completed')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // User progress record doesn't exist yet, create it
        await _supabase.from('usr_progress').insert({
          'user_id': userId,
          'orientation_completed': false,
        });
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
          .from('usr_progress')
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
          .eq('name', 'Orientation')
          .maybeSingle();

      if (response == null) return null;
      return Department.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get orientation department: $e');
    }
  }
}
