/// Centralized game type constants and utilities.
/// All question type strings are defined here to eliminate hardcoding.
library;

/// Game type identifiers used throughout the app.
/// These are the internal type strings stored in question data maps.
class GameType {
  GameType._(); // Prevent instantiation

  static const String multipleChoice = 'multiple_choice';
  static const String scenarioDecision = 'scenario_decision';
  static const String singleTapChoice = 'single_tap_choice';
  static const String matchFollowing = 'match_following';
  static const String cardMatch = 'card_match';
  static const String sequenceBuilder = 'sequence_builder';
  static const String simulation = 'simulation';

  /// All known game types
  static const List<String> all = [
    multipleChoice,
    scenarioDecision,
    singleTapChoice,
    matchFollowing,
    cardMatch,
    sequenceBuilder,
    simulation,
  ];

  /// Types that use the standard MCQ renderer (radio-button style options)
  static const List<String> mcqTypes = [
    multipleChoice,
    scenarioDecision,
    singleTapChoice,
  ];

  /// Types that are interactive games (score stored in gameScores, not questionPoints)
  static const List<String> gameTypes = [
    cardMatch,
    sequenceBuilder,
    simulation,
  ];

  /// Types whose options should NOT be parsed as MCQ [{text, is_correct}]
  static const List<String> rawOptionTypes = [
    cardMatch,
    sequenceBuilder,
    simulation,
    matchFollowing,
  ];

  /// Check if a type uses the MCQ renderer
  static bool isMcq(String type) => mcqTypes.contains(type);

  /// Check if a type is an interactive game
  static bool isGame(String type) => gameTypes.contains(type);

  /// Check if a type preserves raw options (no MCQ parsing)
  static bool preservesRawOptions(String type) => rawOptionTypes.contains(type);
}

/// Maps admin UI type strings → database `quest_types.type` values.
class GameTypeDbMapping {
  GameTypeDbMapping._();

  /// Admin UI type → DB type
  static const Map<String, String> uiToDb = {
    'multiple_choice': 'mcq',
    'match_following': 'match',
    'scenario_decision': 'scenario_decision',
    'card_match': 'card_match',
    'sequence_builder': 'sequence_builder',
    'simulation': 'simulation',
  };

  /// Convert admin UI type to DB type string
  static String toDbType(String uiType) => uiToDb[uiType] ?? uiType;
}

/// Detects question type from the options JSONB structure.
/// This is the most reliable detection method — title-based is fallback only.
class GameTypeDetector {
  GameTypeDetector._();

  /// Detect game type from options data structure.
  /// Returns null if no structure match found (caller should fall back to title).
  static String? fromOptionsStructure(dynamic optionsRaw) {
    if (optionsRaw == null) return null;

    // Map-based structures
    if (optionsRaw is Map) {
      // Budget simulation: {total_budget: int, departments: [...]}
      if (optionsRaw.containsKey('total_budget') &&
          optionsRaw.containsKey('departments')) {
        return GameType.simulation;
      }
      // Card match (bucket style): {cards: [...], buckets: [...]}
      if (optionsRaw.containsKey('cards') &&
          optionsRaw.containsKey('buckets')) {
        return GameType.cardMatch;
      }
    }

    // List-based structures
    if (optionsRaw is List && optionsRaw.isNotEmpty && optionsRaw[0] is Map) {
      final first = optionsRaw[0] as Map;

      // Match following: [{left, right}, ...]
      if (first.containsKey('left') && first.containsKey('right')) {
        return GameType.matchFollowing;
      }
      // Sequence builder: [{id, text, correct_position}, ...]
      if (first.containsKey('text') && first.containsKey('correct_position')) {
        return GameType.sequenceBuilder;
      }
      // Card flip game: [{id, question, answer}, ...]
      if (first.containsKey('question') && first.containsKey('answer')) {
        return GameType.cardMatch;
      }
    }

    return null; // No structure match
  }

  /// Fallback: detect game type from title keywords.
  static String fromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('single tap')) return GameType.singleTapChoice;
    if (t.contains('card match') || t.contains('card_match')) {
      return GameType.cardMatch;
    }
    if (t.contains('scenario') || t.contains('decision')) {
      return GameType.scenarioDecision;
    }
    if (t.contains('sequence') || t.contains('arrange') || t.contains('order')) {
      return GameType.sequenceBuilder;
    }
    if (t.contains('simulation') || t.contains('budget')) {
      return GameType.simulation;
    }
    if (t.contains('match')) return GameType.matchFollowing;
    return GameType.multipleChoice; // Default
  }

  /// Full detection: structure first, then title fallback.
  static String detect(dynamic optionsRaw, String title) {
    return fromOptionsStructure(optionsRaw) ?? fromTitle(title);
  }
}
