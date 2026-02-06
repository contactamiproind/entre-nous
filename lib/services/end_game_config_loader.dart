import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/end_game_config.dart';
import 'end_game_service.dart';

/// Service for loading and saving End Game configurations
class EndGameConfigLoader {
  static final EndGameService _endGameService = EndGameService();
  
  /// Load the currently active venue configuration
  /// Checks database first for user-specific assignment, then falls back to JSON
  static Future<VenueConfig> loadActiveVenue() async {
    try {
      // Try to get user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId != null) {
        // Check database for user-specific config
        final dbConfig = await _endGameService.getActiveConfigForUser(userId);
        
        if (dbConfig != null && dbConfig['venue_data'] != null) {
          return VenueConfig.fromJson(dbConfig['venue_data'] as Map<String, dynamic>);
        }
      }
      
      // Fall back to JSON file
      // Load active venue ID
      final activeVenueJson = await rootBundle.loadString('assets/end_game/active_venue.json');
      final activeVenueData = json.decode(activeVenueJson) as Map<String, dynamic>;
      final activeVenueId = activeVenueData['activeVenueId'] as String;

      // Load the venue configuration
      final venueJson = await rootBundle.loadString('assets/end_game/venues/${activeVenueId}_venue.json');
      final venueData = json.decode(venueJson) as Map<String, dynamic>;
      
      return VenueConfig.fromJson(venueData);
    } catch (e) {
      print('Error loading active venue: $e');
      // Return default venue as fallback
      return loadVenue('default');
    }
  }

  /// Load a specific venue by ID
  static Future<VenueConfig> loadVenue(String venueId) async {
    try {
      final venueJson = await rootBundle.loadString('assets/end_game/venues/${venueId}_venue.json');
      final venueData = json.decode(venueJson) as Map<String, dynamic>;
      return VenueConfig.fromJson(venueData);
    } catch (e) {
      print('Error loading venue $venueId: $e');
      rethrow;
    }
  }

  /// Load all items configuration
  /// Checks database first for user-specific assignment, then falls back to JSON
  static Future<ItemsConfig> loadItems() async {
    try {
      // Try to get user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId != null) {
        // Check database for user-specific config
        final dbConfig = await _endGameService.getActiveConfigForUser(userId);
        
        if (dbConfig != null && dbConfig['items_data'] != null) {
          return ItemsConfig.fromJson(dbConfig['items_data'] as Map<String, dynamic>);
        }
      }
      
      // Fall back to JSON file
      final itemsJson = await rootBundle.loadString('assets/end_game/items_config.json');
      final itemsData = json.decode(itemsJson) as Map<String, dynamic>;
      return ItemsConfig.fromJson(itemsData);
    } catch (e) {
      print('Error loading items: $e');
      rethrow;
    }
  }

  /// Get list of available venue IDs
  static Future<List<String>> getAvailableVenues() async {
    // For now, return hardcoded list
    return ['default'];
  }

  /// Save venue configuration (deprecated - use EndGameService instead)
  static Future<void> saveVenue(VenueConfig venue) async {
    throw UnimplementedError(
      'Use EndGameService.saveConfig() instead'
    );
  }

  /// Set the active venue (deprecated - use EndGameService instead)
  static Future<void> setActiveVenue(String venueId) async {
    throw UnimplementedError(
      'Use EndGameService.setActiveConfig() instead'
    );
  }
}
