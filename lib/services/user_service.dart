import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String userId;
  final String email;
  final String role;
  final DateTime? createdAt;

  UserProfile({
    required this.userId,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all users (excluding admins by default)
  Future<List<UserProfile>> getAllUsers({bool includeAdmins = false}) async {
    try {
      var query = _supabase.from('profiles').select();
      
      if (!includeAdmins) {
        query = query.eq('role', 'user');
      }
      
      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Create a new user with Supabase Auth
  /// Note: The profile is automatically created by a database trigger
  Future<UserProfile> createUser({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create auth user');
      }

      final userId = authResponse.user!.id;

      // Wait for trigger to create profile
      await Future.delayed(const Duration(milliseconds: 1000));

      // Update role if not 'user' (trigger creates with 'user' role by default)
      if (role != 'user') {
        await _supabase
            .from('profiles')
            .update({'role': role})
            .eq('user_id', userId);
      }

      return UserProfile(
        userId: userId,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUser({
    required String userId,
    String? role,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (role != null) updates['role'] = role;
      
      if (updates.isEmpty) return;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user and all related data
  Future<void> deleteUser(String userId, {bool deleteAuth = false}) async {
    try {
      // Delete user progress
      await _supabase.from('usr_stat').delete().eq('user_id', userId);

      // Delete pathway assignments
      await _supabase.from('user_pathway').delete().eq('user_id', userId);

      // Delete profile
      await _supabase.from('profiles').delete().eq('user_id', userId);

      // Optionally delete from Supabase Auth
      // Note: This requires admin privileges
      if (deleteAuth) {
        // This would need to be done via Supabase Admin API
        // For now, we'll skip this as it requires special permissions
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Assign pathway to user with questions
  Future<String> assignPathway({
    required String userId,
    required String pathwayId,
  }) async {
    try {
      final result = await _supabase.rpc(
        'assign_pathway_with_questions',
        params: {
          'p_user_id': userId,
          'p_dept_id': pathwayId,
          'p_assigned_by': _supabase.auth.currentUser?.id,
        },
      );
      return result as String; // Returns usr_dept_id
    } catch (e) {
      throw Exception('Failed to assign pathway: $e');
    }
  }

  /// Remove pathway assignment
  Future<void> removePathwayAssignment({
    required String userId,
    required String pathwayId,
  }) async {
    try {
      await _supabase
          .from('usr_dept')
          .delete()
          .eq('user_id', userId)
          .eq('dept_id', pathwayId);
    } catch (e) {
      throw Exception('Failed to remove pathway assignment: $e');
    }
  }

  /// Get user pathways
  Future<List<Map<String, dynamic>>> getUserPathways(String userId) async {
    try {
      final response = await _supabase
          .from('usr_dept')
          .select('*, departments(*)')
          .eq('user_id', userId);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch user pathways: $e');
    }
  }
}
