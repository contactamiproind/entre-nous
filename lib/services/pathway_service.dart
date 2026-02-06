import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pathway.dart';

class PathwayService {
  final _supabase = Supabase.instance.client;

  // Get all pathways (departments)
  Future<List<Pathway>> getAllPathways() async {
    final response = await _supabase
        .from('departments')
        .select()
        .order('title');

    return (response as List)
        .map((json) => Pathway.fromJson(json))
        .toList();
  }

  // Get pathway by ID
  Future<Pathway?> getPathwayById(String id) async {
    final response = await _supabase
        .from('departments')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Pathway.fromJson(response);
  }

  // Get pathway levels from the departments.levels JSONB column
  Future<List<PathwayLevel>> getPathwayLevels(String pathwayId) async {
    final response = await _supabase
        .from('departments')
        .select('id, levels')
        .eq('id', pathwayId)
        .maybeSingle();

    if (response == null || response['levels'] == null) {
      return [];
    }

    // Parse the levels JSONB array
    final levelsJson = response['levels'] as List<dynamic>;
    
    return levelsJson.asMap().entries.map((entry) {
      final index = entry.key;
      final levelData = entry.value as Map<String, dynamic>;
      
      // Create a PathwayLevel from the JSONB data
      // Generate an ID if not present
      return PathwayLevel.fromJson({
        'id': levelData['id']?.toString() ?? '${pathwayId}_level_${index + 1}',
        'dept_id': pathwayId,
        'level_number': levelData['number'] ?? levelData['level_number'] ?? (index + 1),
        'level_name': levelData['name'] ?? levelData['level_name'] ?? 'Level ${index + 1}',
        'title': levelData['name'] ?? levelData['title'] ?? levelData['level_name'] ?? 'Level ${index + 1}',
        'required_score': levelData['score'] ?? levelData['required_score'] ?? 0,
        'description': levelData['description'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }).toList();
  }

  // Check if orientation is completed
  Future<bool> isOrientationCompleted(String userId) async {
    // Check if user has completed orientation by looking at usr_dept
    final orientationDept = await getOrientationPathway();
    if (orientationDept == null) return false;
    
    final response = await _supabase
        .from('usr_dept')
        .select()
        .eq('user_id', userId)
        .eq('dept_id', orientationDept.id)
        .maybeSingle();

    if (response == null) return false;
    
    // Consider orientation complete if they have answered questions
    final answeredQuestions = response['answered_questions'] as int? ?? 0;
    return answeredQuestions > 0;
  }

  // Mark orientation as complete
  Future<void> markOrientationComplete(String userId) async {
    // With new schema, orientation is automatically "complete" when questions are answered
    // This method is kept for compatibility but doesn't need to do anything
    // The usr_stat table tracks all answers automatically
    return;
  }

  // Get orientation pathway
  Future<Pathway?> getOrientationPathway() async {
    final response = await _supabase
        .from('departments')
        .select()
        .eq('category', 'Orientation')
        .maybeSingle();

    if (response == null) return null;
    return Pathway.fromJson(response);
  }

  // Create pathway level by updating the departments.levels JSONB array
  Future<void> createPathwayLevel({
    required String pathwayId,
    required int levelNumber,
    required String levelName,
    required int requiredScore,
    String? description,
  }) async {
    // Get current levels
    final currentLevels = await getPathwayLevels(pathwayId);
    
    // Create new level object
    final newLevel = {
      'id': '${pathwayId}_level_$levelNumber',
      'number': levelNumber,
      'name': levelName,
      'score': requiredScore,
      'description': description,
    };
    
    // Add to levels array
    final updatedLevels = [
      ...currentLevels.map((l) => {
        'id': l.id,
        'number': l.levelNumber,
        'name': l.levelName,
        'score': l.requiredScore,
        'description': l.description,
      }),
      newLevel,
    ];
    
    // Update the department with new levels array
    await _supabase.from('departments').update({
      'levels': updatedLevels,
    }).eq('id', pathwayId);
  }
}
