import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/end_game_config.dart';

class EndGameService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Load all End Game configurations
  Future<List<Map<String, dynamic>>> loadAllConfigs() async {
    try {
      final response = await _supabase
          .from('end_game_configs')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load End Game configs: $e');
    }
  }

  /// Load a specific End Game configuration by ID
  Future<Map<String, dynamic>?> loadConfigById(String id) async {
    try {
      final response = await _supabase
          .from('end_game_configs')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      throw Exception('Failed to load End Game config: $e');
    }
  }

  /// Get active End Game for current user
  Future<Map<String, dynamic>?> getActiveConfigForUser(String userId) async {
    try {
      // First check if user has a specific assignment
      final assignment = await _supabase
          .from('end_game_assignments')
          .select('end_game_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (assignment != null) {
        // Load the assigned End Game
        return await loadConfigById(assignment['end_game_id']);
      }

      // If no specific assignment, return the default active config
      final response = await _supabase
          .from('end_game_configs')
          .select()
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get active End Game: $e');
    }
  }

  /// Save or update End Game configuration
  Future<String> saveConfig({
    String? id,
    required String name,
    required int level,
    required Map<String, dynamic> venueData,
    required Map<String, dynamic> itemsData,
    bool isActive = false,
  }) async {
    try {
      final data = {
        'name': name,
        'level': level,
        'venue_data': venueData,
        'items_data': itemsData,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (id != null) {
        // Update existing
        await _supabase
            .from('end_game_configs')
            .update(data)
            .eq('id', id);
        return id;
      } else {
        // Create new
        final response = await _supabase
            .from('end_game_configs')
            .insert(data)
            .select('id')
            .single();
        return response['id'];
      }
    } catch (e) {
      throw Exception('Failed to save End Game config: $e');
    }
  }

  /// Delete End Game configuration
  Future<void> deleteConfig(String id) async {
    try {
      await _supabase
          .from('end_game_configs')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete End Game config: $e');
    }
  }

  /// Assign End Game to users
  Future<void> assignToUsers(String endGameId, List<String> userIds) async {
    try {
      // First, remove existing assignments for this End Game
      await _supabase
          .from('end_game_assignments')
          .delete()
          .eq('end_game_id', endGameId);

      // Then add new assignments
      if (userIds.isNotEmpty) {
        final assignments = userIds.map((userId) => {
          'end_game_id': endGameId,
          'user_id': userId,
        }).toList();

        await _supabase
            .from('end_game_assignments')
            .insert(assignments);
      }
    } catch (e) {
      throw Exception('Failed to assign End Game to users: $e');
    }
  }

  /// Mark End Game assignment as completed
  Future<void> markAsCompleted(String userId, String endGameId, int score) async {
    try {
      debugPrint('🎮 Marking End Game $endGameId as completed for user $userId with score $score');
      
      final response = await _supabase
          .from('end_game_assignments')
          .update({
            'completed_at': DateTime.now().toIso8601String(),
            'score': score,
          })
          .eq('user_id', userId)
          .eq('end_game_id', endGameId)
          .select();
          
      debugPrint('🎮 Update response: $response');
      
      if (response.isEmpty) {
        debugPrint('❌ WARNING: No execution rows updated! Check if user_id and end_game_id match exactly.');
      }
    } catch (e) {
      debugPrint('❌ Failed to mark End Game as completed: $e');
      throw Exception('Failed to mark End Game as completed: $e');
    }
  }

  /// Check if End Game for a specific level is completed
  Future<bool> isLevelCompleted(String userId, int level) async {
    try {
      // 1. Find the active End Game config for this level
      final config = await _supabase
          .from('end_game_configs')
          .select('id')
          .eq('level', level)
          .eq('is_active', true)
          .maybeSingle();

      if (config == null) return true; // No End Game for this level -> considered complete

      final endGameId = config['id'];

      // 2. Check if user has completed this assignment
      final assignment = await _supabase
          .from('end_game_assignments')
          .select('completed_at')
          .eq('user_id', userId)
          .eq('end_game_id', endGameId)
          .maybeSingle();

      if (assignment != null && assignment['completed_at'] != null) {
        return true;
      }
      
      return false;
    } catch (e) {
      // If error, assume not completed to be safe
      return false;
    }
  }

  /// Get users assigned to an End Game
  Future<List<String>> getAssignedUsers(String endGameId) async {
    try {
      final response = await _supabase
          .from('end_game_assignments')
          .select('user_id')
          .eq('end_game_id', endGameId);

      return List<String>.from(response.map((r) => r['user_id']));
    } catch (e) {
      throw Exception('Failed to get assigned users: $e');
    }
  }

  /// Load all users for assignment selector
  Future<List<Map<String, dynamic>>> loadAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('user_id, full_name, email')
          .order('full_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  /// Set a config as active (and deactivate others)
  Future<void> setActiveConfig(String id) async {
    try {
      // Deactivate all configs
      await _supabase
          .from('end_game_configs')
          .update({'is_active': false})
          .neq('id', '00000000-0000-0000-0000-000000000000'); // Update all

      // Activate the selected one
      await _supabase
          .from('end_game_configs')
          .update({'is_active': true})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to set active config: $e');
    }
  }
}
