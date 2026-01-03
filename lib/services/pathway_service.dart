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

  // Get pathway levels
  Future<List<PathwayLevel>> getPathwayLevels(String pathwayId) async {
    final response = await _supabase
        .from('dept_levels')
        .select()
        .eq('dept_id', pathwayId)
        .order('level_number');

    return (response as List)
        .map((json) => PathwayLevel.fromJson(json))
        .toList();
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
        .eq('title', 'Orientation')
        .maybeSingle();

    if (response == null) return null;
    return Pathway.fromJson(response);
  }

  // Create pathway level
  Future<void> createPathwayLevel({
    required String pathwayId,
    required int levelNumber,
    required String levelName,
    required int requiredScore,
    String? description,
  }) async {
    await _supabase.from('dept_levels').insert({
      'dept_id': pathwayId,
      'level_number': levelNumber,
      'level_name': levelName,
      'required_score': requiredScore,
      'description': description,
    });
  }
}
