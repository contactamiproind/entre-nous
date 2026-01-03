import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class StorageService {
  static const String _currentUserIdKey = 'currentUserId';
  static SupabaseClient get _supabase => Supabase.instance.client;

  // Initialize - just check Supabase connection
  static Future<void> initializeDefaultUsers() async {
    try {
      // Check if profiles table exists
      await _supabase
          .from('profiles')
          .select()
          .limit(1);
      
      // Connection successful
    } catch (e) {
      // Connection failed - will be handled by individual operations
    }
  }

  // Save current logged-in user ID
  static Future<void> saveCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
  }

  // Get current logged-in user ID
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey);
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    await _supabase.auth.signOut();
  }

  // ============================================
  // PROFILE METHODS
  // ============================================

  // Get profile for current user
  static Future<Profile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (response == null) return null;
      
      return Profile.fromJson(response);
    } catch (e) {
      // Error fetching profile
      return null;
    }
  }

  // Get profile by user ID
  static Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      
      return Profile.fromJson(response);
    } catch (e) {
      // Error fetching profile
      return null;
    }
  }

  // Create or update profile
  static Future<bool> saveProfile(String userId, Profile profile) async {
    try {
      // Check if profile exists
      final existing = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      final profileData = profile.toJson();
      profileData['user_id'] = userId;
      
      if (existing == null) {
        // Insert new profile
        await _supabase.from('profiles').insert(profileData);
      } else {
        // Update existing profile
        await _supabase
            .from('profiles')
            .update(profileData)
            .eq('user_id', userId);
      }
      
      return true;
    } catch (e) {
      // Error saving profile
      return false;
    }
  }

  // Get all profiles (for admin)
  static Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Error fetching profiles
      return [];
    }
  }

  // ============================================
  // QUIZ PROGRESS METHODS (if needed)
  // ============================================

  // Save quiz progress
  static Future<void> saveQuizProgress({
    required String userId,
    required int level,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      await _supabase.from('quiz_progress').insert({
        'user_id': userId,
        'level': level,
        'score': score,
        'total_questions': totalQuestions,
      });
    } catch (e) {
      // Error saving quiz progress
    }
  }

  // Get quiz history for a user
  static Future<List<Map<String, dynamic>>> getQuizHistory(String userId) async {
    try {
      final response = await _supabase
          .from('quiz_progress')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Error fetching quiz history
      return [];
    }
  }
}
